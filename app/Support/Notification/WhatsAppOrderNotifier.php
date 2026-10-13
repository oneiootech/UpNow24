<?php

namespace App\Support\Notification;

use App\Models\Setting;
use Illuminate\Support\Facades\Log;

class WhatsAppOrderNotifier
{
    /**
     * Send WhatsApp alert to the store/seller when a new order is received.
     */
    public static function notifySellerNewOrder($order): bool
    {
        $sellerPhone = $order?->store?->phone ?? $order?->store?->vendor?->phone;
        if (empty($sellerPhone)) {
            return false;
        }

        $orderId = (string)($order->id ?? '');
        $storeName = (string)($order->store?->name ?? 'Your Store');
        $amount = (string)number_format((float)($order->order_amount ?? 0), 2);
        $paymentMethod = ucwords(str_replace('_', ' ', (string)($order->payment_method ?? 'Cash On Delivery')));

        $message = "📦 *New Order Received!*\n\n"
            . "• *Order ID:* #{$orderId}\n"
            . "• *Store:* {$storeName}\n"
            . "• *Amount:* ₹{$amount}\n"
            . "• *Payment:* {$paymentMethod}\n\n"
            . "Please open your UpNow24 Seller panel to accept and prepare the order.";

        $setting = Setting::where('settings_type', 'sms_config')->where('key_name', 'custom_otp')->first();
        $template = $setting?->live_values['seller_order_template'] ?? 'seller_order_alert';

        return self::dispatchWhatsApp($sellerPhone, $message, [
            'template'  => $template,
            'event'     => 'SELLER_NEW_ORDER',
            'order_id'  => $orderId,
            'variables' => [
                '1' => $orderId,
                '2' => $storeName,
                '3' => $amount,
                '4' => $paymentMethod,
            ],
        ]);
    }

    /**
     * Send WhatsApp alert to the customer when order status changes.
     */
    public static function notifyCustomerOrderStatus($order, string $status): bool
    {
        $customerPhone = null;
        $customerName = 'Customer';

        if ($order->is_guest) {
            $customerDetails = json_decode((string)$order->delivery_address, true);
            $customerPhone = data_get($customerDetails, 'contact_person_number');
            $customerName = data_get($customerDetails, 'contact_person_name') ?? 'Customer';
        } else {
            $customerPhone = $order->customer?->phone;
            $customerName = trim(($order->customer?->f_name ?? '') . ' ' . ($order->customer?->l_name ?? '')) ?: 'Customer';
        }

        if (empty($customerPhone)) {
            return false;
        }

        $orderId = (string)($order->id ?? '');
        $storeName = (string)($order->store?->name ?? 'Store');
        $amount = (string)number_format((float)($order->order_amount ?? 0), 2);

        $statusText = match ($status) {
            'pending', 'confirmed' => "Your order #{$orderId} from {$storeName} has been confirmed!",
            'processing'           => "Great news! {$storeName} is now preparing your order #{$orderId}.",
            'handover', 'picked_up' => "Your order #{$orderId} has been picked up and is on its way to you!",
            'delivered'            => "Your order #{$orderId} has been delivered. Thank you for choosing UpNow24!",
            'canceled'             => "Your order #{$orderId} from {$storeName} has been canceled.",
            default                => null,
        };

        if ($statusText === null) {
            return false;
        }

        $message = "🛍️ *Order Update - UpNow24*\n\n"
            . "Hi {$customerName},\n"
            . "{$statusText}\n\n"
            . "• *Order ID:* #{$orderId}\n"
            . "• *Amount:* ₹{$amount}\n"
            . "• *Store:* {$storeName}\n\n"
            . "Track your order live in the UpNow24 App.";

        $setting = Setting::where('settings_type', 'sms_config')->where('key_name', 'custom_otp')->first();
        $template = $setting?->live_values['customer_order_template'] ?? 'customer_order_alert';

        return self::dispatchWhatsApp($customerPhone, $message, [
            'template'  => $template,
            'event'     => 'CUSTOMER_ORDER_' . strtoupper($status),
            'order_id'  => $orderId,
            'status'    => $status,
            'variables' => [
                '1' => $customerName,
                '2' => $orderId,
                '3' => $storeName,
                '4' => $amount,
            ],
        ]);
    }

    /**
     * Dispatch WhatsApp message using active custom_otp gateway credentials.
     */
    public static function dispatchWhatsApp(string $receiver, string $message, array $extra = []): bool
    {
        $setting = Setting::where('settings_type', 'sms_config')->where('key_name', 'custom_otp')->first();
        if (!$setting || (int)($setting->live_values['status'] ?? 0) !== 1) {
            return false;
        }

        $config = $setting->live_values;
        $apiUrl = $config['api_url'] ?? 'https://wpcrm.furtikart.com/api/v1/gateway/otp';
        $token = trim($config['token'] ?? '');

        if (empty($token)) {
            return false;
        }

        // Clean recipient digits
        $receiver = preg_replace('/\D+/', '', (string)$receiver);
        if (strlen($receiver) === 10) {
            $receiver = '91' . $receiver;
        }

        // Never send to business sender number itself
        if ($receiver === '918982049143') {
            return false;
        }

        $payload = array_merge([
            'mobile'  => $receiver,
            'message' => $message,
            'phone'   => $receiver,
            'to'      => $receiver,
        ], $extra);

        $headers = [
            'Content-Type: application/json',
            'Accept: application/json',
            'Authorization: ' . (str_starts_with($token, 'Bearer ') ? $token : 'Bearer ' . $token),
        ];

        try {
            $curl = curl_init();
            curl_setopt_array($curl, [
                CURLOPT_URL            => $apiUrl,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_CUSTOMREQUEST  => 'POST',
                CURLOPT_POSTFIELDS     => json_encode($payload),
                CURLOPT_HTTPHEADER     => $headers,
                CURLOPT_CONNECTTIMEOUT => 5,
                CURLOPT_TIMEOUT        => 20,
                CURLOPT_SSL_VERIFYPEER => config('notification.sms.verify_ssl', !app()->isLocal()),
                CURLOPT_SSL_VERIFYHOST => config('notification.sms.verify_ssl', !app()->isLocal()) ? 2 : 0,
            ]);

            $result = curl_exec($curl);
            $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
            $curlErr = curl_error($curl);
            curl_close($curl);

            if ($curlErr) {
                Log::channel(NotificationConfig::logChannel())->error('whatsapp_order_notify.curl_error', [
                    'receiver' => $receiver,
                    'error'    => $curlErr,
                ]);
                return false;
            }

            $json = json_decode((string)$result, true);
            $success = ($httpCode >= 200 && $httpCode < 300) && (($json['status'] ?? '') === 'success' || isset($json['provider_message_id']));

            if (!$success) {
                Log::channel(NotificationConfig::logChannel())->warning('whatsapp_order_notify.failed', [
                    'receiver' => $receiver,
                    'httpCode' => $httpCode,
                    'response' => $result,
                ]);
            }

            return $success;
        } catch (\Throwable $e) {
            Log::channel(NotificationConfig::logChannel())->error('whatsapp_order_notify.exception', [
                'receiver' => $receiver,
                'error'    => $e->getMessage(),
            ]);
            return false;
        }
    }
}

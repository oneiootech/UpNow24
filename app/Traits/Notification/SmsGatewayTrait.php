<?php

namespace App\Traits\Notification;

use App\Services\Payment\SettingService;
use App\Support\Notification\NotificationConfig;
use Illuminate\Support\Facades\Log;
use Twilio\Rest\Client;

trait SmsGatewayTrait
{
    private static ?array $smsGatewayConfigs = null;

    public static function send($receiver, $otp)
    {
        return match (true) {
            self::smsGatewayActive('custom_otp') => self::customOtp($receiver, $otp),
            self::smsGatewayActive('twilio') => self::twilio($receiver, $otp),
            self::smsGatewayActive('nexmo') => self::nexmo($receiver, $otp),
            self::smsGatewayActive('2factor') => self::twoFactor($receiver, $otp),
            self::smsGatewayActive('msg91') => self::msg91($receiver, $otp),
            self::smsGatewayActive('alphanet_sms') => self::alphanetSms($receiver, $otp),
            default => 'not_found',
        };
    }

    public static function testGateway(string $gateway, string $receiver, ?string $otp = null, string $testType = 'otp'): array
    {
        $receiver = trim((string)$receiver);
        $otp = $otp ?: (string)rand(100000, 999999);

        if ($gateway === 'custom_otp') {
            $config = self::smsGatewaySettings('custom_otp');
            if (!$config) {
                return [
                    'success' => false,
                    'message' => 'Custom WhatsApp gateway is not configured.',
                ];
            }

            $apiUrl = $config['api_url'] ?? 'https://wpcrm.furtikart.com/api/v1/gateway/otp';
            $token = trim($config['token'] ?? $config['api_key'] ?? '');

            if (empty($token)) {
                return [
                    'success' => false,
                    'message' => 'API Token / Bearer key is empty. Please enter your API token.',
                ];
            }

            $cleanDigits = preg_replace('/\D+/', '', $receiver);
            if ($cleanDigits === '918982049143' || $cleanDigits === '8982049143') {
                return [
                    'success' => false,
                    'message' => 'WhatsApp Cloud API limitation: You cannot send a test message to the registered sender number itself (+91 89820 49143). Please enter another mobile number.',
                ];
            }

            $template = 'otp';
            if ($testType === 'seller_order') {
                $template = $config['seller_order_template'] ?? 'seller_order_alert';
                $orderId = (string)rand(100100, 100999);
                $itemDetails = "Mango (₹99), Mojito (₹49)";
                $storeName = 'Example Store';
                $amount = '148.00';
                $message = "📦 *New Order Alert!*\n\n"
                    . "Order ID: #{$orderId}\n\n"
                    . "*Item details:*\n{$itemDetails}\n\n"
                    . "Store: {$storeName}\n"
                    . "Amount: ₹{$amount}\n\n"
                    . "Please open your UpNow24 App to *Accept & prepare* the order.";

                $payload = [
                    'mobile'    => $receiver,
                    'phone'     => $receiver,
                    'template'  => $template,
                    'event'     => 'SELLER_NEW_ORDER',
                    'order_id'  => $orderId,
                    'variables' => [
                        '1' => $orderId,
                        '2' => $itemDetails,
                        '3' => $storeName,
                        '4' => $amount,
                    ],
                    'message'   => $message,
                ];
            } elseif ($testType === 'customer_order') {
                $template = $config['customer_order_template'] ?? 'customer_order_alert';
                $orderId = (string)rand(100100, 100999);
                $itemDetails = "Mango (₹99), Mojito (₹49)";
                $storeName = 'Example Store';
                $paymentMethod = 'Cash On Delivery';
                $orderType = 'Delivery';
                $paymentStatus = 'Unpaid';
                $message = "🛍️ *Order Confirmed - UpNow24*\n\n"
                    . "• *Order:* #{$orderId}\n"
                    . "• *Payment method:* {$paymentMethod}\n"
                    . "• *Order Type:* {$orderType}\n"
                    . "• *Payment status:* {$paymentStatus}\n\n"
                    . "*Item details:*\n{$itemDetails}\n\n"
                    . "• *Store information:* {$storeName}\n\n"
                    . "✅ *Order Is Confirmed Deliverd Soon*";

                $payload = [
                    'mobile'    => $receiver,
                    'phone'     => $receiver,
                    'template'  => $template,
                    'event'     => 'CUSTOMER_ORDER_CONFIRMED',
                    'order_id'  => $orderId,
                    'status'    => 'confirmed',
                    'variables' => [
                        '1' => $orderId,
                        '2' => $paymentMethod,
                        '3' => $orderType,
                        '4' => $paymentStatus,
                        '5' => $itemDetails,
                        '6' => $storeName,
                    ],
                    'message'   => $message,
                ];
            } else {
                $template = $config['otp_template'] ?? 'Your verification code is #OTP#';
                $message = str_replace("#OTP#", $otp, $template);
                $payload = [
                    'mobile'  => $receiver,
                    'otp'     => (string)$otp,
                    'message' => $message,
                ];
            }

            $headers = [
                'Content-Type: application/json',
                'Accept: application/json',
                'Authorization: ' . (str_starts_with($token, 'Bearer ') ? $token : 'Bearer ' . $token),
            ];

            try {
                $curl = curl_init();
                curl_setopt_array($curl, [
                    CURLOPT_URL => $apiUrl,
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_CUSTOMREQUEST => 'POST',
                    CURLOPT_POSTFIELDS => json_encode($payload),
                    CURLOPT_HTTPHEADER => $headers,
                    CURLOPT_CONNECTTIMEOUT => self::smsConnectTimeout(),
                    CURLOPT_TIMEOUT => self::smsTimeout(),
                    CURLOPT_SSL_VERIFYPEER => config('notification.sms.verify_ssl', !app()->isLocal()),
                    CURLOPT_SSL_VERIFYHOST => config('notification.sms.verify_ssl', !app()->isLocal()) ? 2 : 0,
                ]);

                $result = curl_exec($curl);
                $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
                $curlErr = curl_error($curl);
                curl_close($curl);

                if ($curlErr) {
                    return [
                        'success' => false,
                        'message' => 'Curl error: ' . $curlErr,
                    ];
                }

                $json = json_decode((string)$result, true);
                if ($httpCode >= 200 && $httpCode < 300 && ((isset($json['status']) && $json['status'] === 'success') || isset($json['provider_message_id']))) {
                    $successMsg = match($testType) {
                        'seller_order' => "Test Seller Order Alert ({$template}) dispatched successfully via WhatsApp!",
                        'customer_order' => "Test Customer Order Alert ({$template}) dispatched successfully via WhatsApp!",
                        default => "OTP dispatched successfully via WhatsApp!",
                    };
                    return [
                        'success' => true,
                        'message' => $successMsg,
                        'provider_message_id' => $json['provider_message_id'] ?? null,
                        'otp' => $otp,
                    ];
                }

                $errMsg = $json['message'] ?? $result ?? ('HTTP code ' . $httpCode);
                return [
                    'success' => false,
                    'message' => (string)$errMsg,
                ];
            } catch (\Throwable $e) {
                return [
                    'success' => false,
                    'message' => 'Exception: ' . $e->getMessage(),
                ];
            }
        }

        // Fallback for other gateways
        $status = self::send($receiver, $otp);
        return [
            'success' => $status === 'success',
            'message' => $status === 'success'
                ? "Test OTP {$otp} sent successfully via {$gateway}!"
                : "Gateway {$gateway} returned status: {$status}",
            'otp' => $otp,
        ];
    }

    public static function customOtp($receiver, $otp, $message = null): string
    {
        $config = self::smsGatewaySettings('custom_otp');
        $response = 'error';

        if (isset($config) && (int)($config['status'] ?? 0) === 1 && (int)($config['otp_status'] ?? 1) === 1) {
            $apiUrl = $config['api_url'] ?? 'https://wpcrm.furtikart.com/api/v1/gateway/otp';
            $token = trim($config['token'] ?? $config['api_key'] ?? '');

            if ($message === null) {
                $template = $config['otp_template'] ?? 'Your verification code is #OTP#';
                $message = str_replace("#OTP#", $otp, $template);
            }

            $receiver = trim((string)$receiver);

            $payload = [
                'mobile' => $receiver,
                'otp' => (string)$otp,
                'message' => $message,
            ];

            $headers = [
                'Content-Type: application/json',
                'Accept: application/json',
            ];

            if ($token !== '') {
                $authHeader = str_starts_with($token, 'Bearer ') ? $token : 'Bearer ' . $token;
                $headers[] = 'Authorization: ' . $authHeader;
            }

            try {
                $curl = curl_init();
                curl_setopt_array($curl, [
                    CURLOPT_URL => $apiUrl,
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_CUSTOMREQUEST => 'POST',
                    CURLOPT_POSTFIELDS => json_encode($payload),
                    CURLOPT_HTTPHEADER => $headers,
                    CURLOPT_CONNECTTIMEOUT => self::smsConnectTimeout(),
                    CURLOPT_TIMEOUT => self::smsTimeout(),
                    CURLOPT_SSL_VERIFYPEER => config('notification.sms.verify_ssl', !app()->isLocal()),
                    CURLOPT_SSL_VERIFYHOST => config('notification.sms.verify_ssl', !app()->isLocal()) ? 2 : 0,
                ]);

                $result = curl_exec($curl);
                $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
                $curlErr = curl_error($curl);
                curl_close($curl);

                if ($curlErr) {
                    self::reportSmsFailure('custom_otp', $receiver, 'Curl error: ' . $curlErr);
                    return 'error';
                }

                $json = json_decode((string)$result, true);
                if ($httpCode >= 200 && $httpCode < 300 && (isset($json['status']) && $json['status'] === 'success')) {
                    $response = 'success';
                } else {
                    $errMsg = $json['message'] ?? $result ?? ('HTTP code ' . $httpCode);
                    self::reportSmsFailure('custom_otp', $receiver, (string)$errMsg);
                    $response = 'error';
                }
            } catch (\Exception $exception) {
                self::reportSmsFailure('custom_otp', $receiver, $exception->getMessage());
                $response = 'error';
            }
        }

        return $response;
    }
    public static function twilio($receiver, $otp): string
    {
        $config = self::smsGatewaySettings('twilio');
        $response = 'error';
        if (isset($config) && $config['status'] == 1) {
            $message = str_replace("#OTP#", $otp, $config['otp_template'] ?? '');
            $sid = $config['sid'];
            $token = $config['token'];
            try {
                $twilio = new Client($sid, $token);
                $twilio->messages
                    ->create($receiver,
                        array(
                            "messagingServiceSid" => $config['messaging_service_sid'],
                            "body" => $message
                        )
                    );
                $response = 'success';
            } catch (\Exception $exception) {
                self::reportSmsFailure('twilio', $receiver, $exception->getMessage());
                $response = 'error';
            }
        }
        return $response;
    }
    public static function nexmo($receiver, $otp): string
    {
        $config = self::smsGatewaySettings('nexmo');
        $response = 'error';
        if (isset($config) && $config['status'] == 1) {
            $message = str_replace("#OTP#", $otp, $config['otp_template'] ?? '');
            try {
                $ch = curl_init();

                curl_setopt($ch, CURLOPT_URL, 'https://rest.nexmo.com/sms/json');
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
                curl_setopt($ch, CURLOPT_POST, 1);
                curl_setopt($ch, CURLOPT_POSTFIELDS, "from=".$config['from']."&text=".$message."&to=".$receiver."&api_key=".$config['api_key']."&api_secret=".$config['api_secret']);

                $headers = array();
                $headers[] = 'Content-Type: application/x-www-form-urlencoded';
                curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
                curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, self::smsConnectTimeout());
                curl_setopt($ch, CURLOPT_TIMEOUT, self::smsTimeout());

                $body = curl_exec($ch);
                $error = curl_error($ch);
                curl_close($ch);

                if ($error !== '') {
                    self::reportSmsFailure('nexmo', $receiver, $error);

                    return 'error';
                }

                $sent = data_get(json_decode((string) $body, true), 'messages.0');
                $status = data_get($sent, 'status');

                if ($status !== null && (string) $status !== '0') {
                    self::reportSmsFailure('nexmo', $receiver, 'status '.$status.': '.(string) data_get($sent, 'error-text'));

                    return 'error';
                }

                $response = 'success';
            } catch (\Exception $exception) {
                self::reportSmsFailure('nexmo', $receiver, $exception->getMessage());
                $response = 'error';
            }
        }
        return $response;
    }
    public static function twoFactor($receiver, $otp): string
    {
        $config = self::smsGatewaySettings('2factor');
        $response = 'error';

        if (isset($config) && $config['status'] == 1) {
            $api_key = $config['api_key'];
            $otp_template = $config['otp_template'] ?? 'Your OTP is: #OTP#';

            $apiUrl = sprintf(
                'https://2factor.in/API/V1/%s/SMS/%s/%s/%s',
                urlencode($api_key),
                urlencode($receiver),
                urlencode($otp),
                urlencode($otp_template)
            );

            $curl = curl_init();
            curl_setopt_array($curl, [
                CURLOPT_URL => $apiUrl,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_ENCODING => "",
                CURLOPT_MAXREDIRS => 10,
                CURLOPT_CONNECTTIMEOUT => self::smsConnectTimeout(),
                CURLOPT_TIMEOUT => self::smsTimeout(),
                CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
                CURLOPT_CUSTOMREQUEST => "GET",
            ]);

            $response = curl_exec($curl);
            $err = curl_error($curl);
            curl_close($curl);

            if ($err) {
                self::reportSmsFailure('2factor', $receiver, $err);
                $response = 'error';
            } else {
                $response = 'success';
            }
        }

        return $response;
    }
    public static function msg91($receiver, $otp): string
    {
        $config = self::smsGatewaySettings('msg91');
        $response = 'error';
        if (isset($config) && $config['status'] == 1) {
            $receiver = str_replace("+", "", $receiver);
            $curl = curl_init();
            curl_setopt_array($curl, array(
                CURLOPT_URL => "https://api.msg91.com/api/v5/otp?template_id=" . $config['template_id'] . "&mobile=" . $receiver . "&authkey=" . $config['auth_key'] . "",
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_ENCODING => "",
                CURLOPT_MAXREDIRS => 10,
                CURLOPT_CONNECTTIMEOUT => self::smsConnectTimeout(),
                CURLOPT_TIMEOUT => self::smsTimeout(),
                CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
                CURLOPT_CUSTOMREQUEST => "GET",
                CURLOPT_POSTFIELDS => "{\"OTP\":\"$otp\"}",
                CURLOPT_HTTPHEADER => array(
                    "content-type: application/json"
                ),
            ));


            $response = curl_exec($curl);
            $err = curl_error($curl);
            curl_close($curl);
            if (!$err) {
                $response = 'success';
            } else {
                self::reportSmsFailure('msg91', $receiver, $err);
                $response = 'error';
            }
        }
        return $response;
    }
    public static function alphanetSms($receiver, $otp, $message = null): string
    {
        $config = self::smsGatewaySettings('alphanet_sms');
        $response = 'error';
        if (isset($config) && $config['status'] == 1) {
            if($message ==  null){
                $message = str_replace("#OTP#", $otp, $config['otp_template'] ?? '');
            }

            $receiver = str_replace("+", "", $receiver);
            $api_key = $config['api_key'];
            $sender_id = $config['sender_id'] ?? null;


            $postfields = array(
                'api_key' => $api_key,
                'msg' => $message,
                'to' => $receiver
            );

            if ($sender_id) {
                $postfields['sender_id'] = $sender_id;
            }


            $curl = curl_init();
            curl_setopt_array($curl, array(
                CURLOPT_URL => 'https://api.sms.net.bd/sendsms',
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_CUSTOMREQUEST => 'POST',
                CURLOPT_POSTFIELDS => $postfields,
                CURLOPT_CONNECTTIMEOUT => self::smsConnectTimeout(),
                CURLOPT_TIMEOUT => self::smsTimeout(),
            ));

            $response = curl_exec($curl);
            curl_close($curl);

            if ((int) data_get(json_decode($response,true),'error') === 0) {
                $response = 'success';
            } else {
                self::reportSmsFailure('alphanet_sms', $receiver, (string) $response);
                $response = 'error';
            }
        }
        return $response;
    }
    public static function smsGatewaySettings($name)
    {
        if (self::$smsGatewayConfigs === null) {
            self::$smsGatewayConfigs = app(SettingService::class)->smsGatewayConfigs();
        }

        return self::$smsGatewayConfigs[$name] ?? null;
    }

    private static function smsGatewayActive(string $name): bool
    {
        $config = self::smsGatewaySettings($name);

        if (!isset($config) || (int)($config['status'] ?? 0) !== 1) {
            return false;
        }

        if ($name === 'custom_otp' && isset($config['otp_status']) && (int)$config['otp_status'] !== 1) {
            return false;
        }

        return true;
    }

    private static function smsConnectTimeout(): int
    {
        return (int) config('notification.sms.connect_timeout', 5);
    }

    private static function smsTimeout(): int
    {
        return (int) config('notification.sms.timeout', 30);
    }

    private static function reportSmsFailure(string $gateway, $receiver, string $error): void
    {
        Log::channel(NotificationConfig::logChannel())->error('sms.send_failed', [
            'gateway' => $gateway,
            'receiver' => self::maskReceiver($receiver),
            'error' => $error,
        ]);
    }

    private static function maskReceiver($receiver): string
    {
        $receiver = (string) $receiver;

        return strlen($receiver) > 4
            ? str_repeat('*', strlen($receiver) - 4).substr($receiver, -4)
            : $receiver;
    }
}

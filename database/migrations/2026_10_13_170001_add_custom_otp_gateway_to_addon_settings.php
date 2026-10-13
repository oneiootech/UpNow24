<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        $existing = DB::table('addon_settings')
            ->where('settings_type', 'sms_config')
            ->where('key_name', 'custom_otp')
            ->first();

        $credentials = json_encode([
            'gateway' => 'custom_otp',
            'mode' => 'live',
            'status' => 1,
            'api_url' => 'https://wpcrm.furtikart.com/api/v1/gateway/otp',
            'token' => 'biz_onex_admin_AgKrgeskZhKcx5ipiPZcuftjymOK108n0r6HRmZ6',
            'otp_template' => 'Your verification code is #OTP#',
            'seller_order_template' => 'seller_order_alert',
            'customer_order_template' => 'customer_order_alert',
        ]);

        if (!$existing) {
            DB::table('addon_settings')->insert([
                'id' => Str::uuid()->toString(),
                'key_name' => 'custom_otp',
                'live_values' => $credentials,
                'test_values' => $credentials,
                'settings_type' => 'sms_config',
                'mode' => 'live',
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        } else {
            DB::table('addon_settings')
                ->where('settings_type', 'sms_config')
                ->where('key_name', 'custom_otp')
                ->update([
                    'live_values' => $credentials,
                    'test_values' => $credentials,
                    'is_active' => 1,
                    'updated_at' => now(),
                ]);
        }

        // Deactivate other SMS gateways so custom_otp is active
        $otherGateways = ['twilio', 'nexmo', '2factor', 'msg91', 'alphanet_sms'];
        foreach ($otherGateways as $gateway) {
            $record = DB::table('addon_settings')
                ->where('settings_type', 'sms_config')
                ->where('key_name', $gateway)
                ->first();

            if ($record && $record->live_values) {
                $hold = json_decode($record->live_values, true);
                if (is_array($hold)) {
                    $hold['status'] = 0;
                    DB::table('addon_settings')
                        ->where('settings_type', 'sms_config')
                        ->where('key_name', $gateway)
                        ->update([
                            'live_values' => json_encode($hold),
                            'test_values' => json_encode($hold),
                            'is_active' => 0,
                            'updated_at' => now(),
                        ]);
                }
            }
        }
    }

    public function down(): void
    {
        DB::table('addon_settings')
            ->where('settings_type', 'sms_config')
            ->where('key_name', 'custom_otp')
            ->delete();
    }
};

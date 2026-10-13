@extends('layouts.admin.app')

@section('title', translate('System module setup'))

@push('css_or_js')
    <link rel="stylesheet" href="{{ asset('public/assets/admin/css/third-party-setup.css') }}">
    <style>
        #toast-container > div {
            word-break: break-word !important;
            overflow-wrap: anywhere !important;
            white-space: normal !important;
            max-width: 400px !important;
            width: auto !important;
            line-height: 1.4 !important;
        }
        .test-sms-result {
            word-break: break-word;
            overflow-wrap: anywhere;
            border-radius: 8px;
        }
        .test-sms-result code {
            word-break: break-all;
            white-space: normal;
            font-size: 11px;
        }
    </style>
@endpush

@section('content')
    @php
        $is_demo = getEnvMode() == 'demo' || env('APP_ENV') == 'demo';
        $addon_overrides = $published_status == 1;

        $secret_keys = ['token', 'api_secret', 'auth_key', 'api_key', 'secret'];

        $gateway_meta = [
            'custom_otp' => ['label' => 'Custom WhatsApp & SMS OTP Gateway', 'hint' => translate('Universal WhatsApp & SMS OTP Gateway via WhatsApp Cloud API / Furtikart.'), 'link' => 'https://wpcrm.furtikart.com/admin/gateway/otp'],
            'twilio' => ['label' => 'Twilio', 'hint' => translate('Credentials live in the Twilio Console dashboard.'), 'link' => 'https://console.twilio.com/'],
            'nexmo' => ['label' => 'Vonage (Nexmo)', 'hint' => translate('Find the API key and secret on the Vonage dashboard.'), 'link' => 'https://dashboard.nexmo.com/'],
            '2factor' => ['label' => '2Factor', 'hint' => translate('Copy the API key from your provider account.'), 'link' => 'https://2factor.in/'],
            'msg91' => ['label' => 'MSG91', 'hint' => translate('Auth key and template ID come from the provider panel.'), 'link' => 'https://control.msg91.com/'],
            'alphanet_sms' => ['label' => 'AlphaNet SMS', 'hint' => translate('Provided by your AlphaNet SMS account manager.'), 'link' => null],
        ];

        $field_labels = [
            'api_url' => 'Custom Gateway API URL',
            'token' => 'Bearer Token / API Key',
            'otp_template' => 'OTP Message Template',
            'seller_order_template' => 'Seller Order Template (Meta)',
            'customer_order_template' => 'Customer Order Template (Meta)',
            'sid' => 'Account SID',
            'messaging_service_sid' => 'Messaging Service SID',
            'template_id' => 'Template ID',
        ];

        $field_hints = [
            'api_url' => translate('Endpoint URL. Default: https://wpcrm.furtikart.com/api/v1/gateway/otp'),
            'token' => translate('Bearer token / API key passed in Authorization header.'),
            'otp_template' => translate('Use #OTP# where the generated code should appear.'),
            'seller_order_template' => translate('Meta approved template name for WhatsApp alert to seller when new order is placed.'),
            'customer_order_template' => translate('Meta approved template name for WhatsApp alert to customer for order updates.'),
            'from' => translate('The sender number or ID recipients will see.'),
            'sender_id' => translate('Approved alphanumeric sender ID, if your account uses one.'),
            'template_id' => translate('ID of the approved DLT template.'),
            'messaging_service_sid' => translate('Optional. Use it when sending through a Twilio Messaging Service.'),
        ];

        $active_gateway = $data_values->first(fn ($item) => (int) ($item->live_values['status'] ?? 0) === 1);
    @endphp

    <div class="content container-fluid tps">
        @include('admin-views.business-settings.partials.third-party-header', [
            'icon' => 'tio-message',
            'title' => translate('messages.Sms gateway setup'),
            'summary' => translate('Choose the gateway that delivers OTP and transactional messages to your users.'),
        ])

        @if ($addon_overrides)
            <div class="tps-note tps-note--warn mb-3 align-items-center">
                <i class="tio-warning"></i>
                <div class="flex-grow-1">
                    {{ translate('The SMS gateway add-on is on, so these settings are disabled. Follow the link to the active ones.') }}
                </div>
                <a href="{{ ! empty($payment_url) ? $payment_url : '#' }}" class="btn btn-outline-primary btn-sm flex-shrink-0">
                    <i class="tio-settings"></i> {{ translate('Settings') }}
                </a>
            </div>
        @else
            <div class="tps-note {{ $active_gateway ? 'tps-note--info' : 'tps-note--muted' }} mb-3">
                <i class="{{ $active_gateway ? 'tio-info' : 'tio-warning-outlined' }}"></i>
                <div>
                    @if ($active_gateway)
                        <strong>{{ $gateway_meta[$active_gateway->key_name]['label'] ?? ucfirst(str_replace('_', ' ', $active_gateway->key_name)) }}</strong>
                        {{ translate('is currently sending your messages. Activating another gateway switches this one off.') }}
                    @else
                        {{ translate('No SMS gateway is active yet. Until one is switched on, users cannot receive OTP or transactional messages by SMS.') }}
                    @endif
                </div>
            </div>
        @endif

        <div class="tps-masonry">
            @foreach ($data_values as $gateway)
                @php
                    $values = $gateway->live_values;
                    $is_active = (int) ($values['status'] ?? 0) === 1;
                    $meta = $gateway_meta[$gateway->key_name] ?? ['label' => ucfirst(str_replace('_', ' ', $gateway->key_name)), 'hint' => null, 'link' => null];
                    $fields = collect($values)->except(['gateway', 'mode', 'status', 'otp_status', 'seller_order_status', 'customer_order_status']);
                @endphp

                <div class="digital_payment_methods {{ $addon_overrides ? 'inactive' : '' }}">
                    <form action="{{ route('admin.business-settings.third-party.sms-module-update', [$gateway->key_name]) }}"
                          method="POST" id="{{ $gateway->key_name }}-form" enctype="multipart/form-data">
                        @csrf
                        @method('post')

                        <div class="tps-card">
                            <div class="tps-card__head">
                                <span class="tps-card__brand">{{ mb_substr($meta['label'], 0, 1) }}</span>
                                <div class="tps-card__titles">
                                    <h2 class="tps-card__title">{{ $meta['label'] }}</h2>
                                    @if (! empty($meta['hint']))
                                        <p class="tps-card__subtitle">{{ $meta['hint'] }}</p>
                                    @endif
                                </div>
                                <div class="tps-card__aside">
                                    <div class="tps-seg">
                                        <input class="{{ \App\CentralLogics\Helpers::get_business_settings('firebase_otp_verification', false) == 1 ? 'firebase-check' : '' }}"
                                               type="radio" id="{{ $gateway->key_name }}-active" name="status" value="1"
                                               {{ $is_active ? 'checked' : '' }}>
                                        <label for="{{ $gateway->key_name }}-active">{{ translate('messages.Active') }}</label>

                                        <input type="radio" id="{{ $gateway->key_name }}-inactive" name="status" value="0"
                                               {{ $is_active ? '' : 'checked' }}>
                                        <label for="{{ $gateway->key_name }}-inactive">{{ translate('messages.Inactive') }}</label>
                                    </div>
                                </div>
                            </div>

                            <div class="tps-card__body">
                                <input type="hidden" name="gateway" value="{{ $gateway->key_name }}">
                                <input type="hidden" name="mode" value="live">

                                <div class="row g-3">
                                    @foreach ($fields as $key => $value)
                                        @php
                                            $is_secret = in_array($key, $secret_keys, true);
                                            $is_optional = $gateway->key_name == 'alphanet_sms' && $key == 'sender_id';
                                            $field_id = $gateway->key_name . '_' . $key;
                                        @endphp

                                        <div class="col-md-6">
                                            <div class="tps-field">
                                                <div class="d-flex justify-content-between align-items-center mb-1">
                                                    <label for="{{ $field_id }}" class="tps-field__label text-capitalize mb-0">
                                                        {{ $field_labels[$key] ?? translate($key) }}
                                                        @if ($is_optional)
                                                            <span class="tps-opt">({{ translate('Optional') }})</span>
                                                        @else
                                                            <span class="tps-req">*</span>
                                                        @endif
                                                    </label>

                                                    @if ($gateway->key_name === 'custom_otp' && in_array($key, ['otp_template', 'seller_order_template', 'customer_order_template']))
                                                        @php
                                                            $status_key = match($key) {
                                                                'otp_template' => 'otp_status',
                                                                'seller_order_template' => 'seller_order_status',
                                                                'customer_order_template' => 'customer_order_status',
                                                            };
                                                            $test_type = match($key) {
                                                                'otp_template' => 'otp',
                                                                'seller_order_template' => 'seller_order',
                                                                'customer_order_template' => 'customer_order',
                                                            };
                                                            $test_label = match($key) {
                                                                'otp_template' => 'OTP Verification',
                                                                'seller_order_template' => 'Seller Order Alert',
                                                                'customer_order_template' => 'Customer Order Alert',
                                                            };
                                                            $item_is_active = (int)($values[$status_key] ?? 1) === 1;
                                                        @endphp
                                                        <div class="tps-seg" style="transform: scale(0.85); transform-origin: right center;">
                                                            <input type="radio" id="{{ $gateway->key_name }}-{{ $status_key }}-active" name="{{ $status_key }}" value="1"
                                                                   {{ $item_is_active ? 'checked' : '' }}>
                                                            <label for="{{ $gateway->key_name }}-{{ $status_key }}-active">{{ translate('messages.Active') }}</label>

                                                            <input type="radio" id="{{ $gateway->key_name }}-{{ $status_key }}-inactive" name="{{ $status_key }}" value="0"
                                                                   {{ $item_is_active ? '' : 'checked' }}>
                                                            <label for="{{ $gateway->key_name }}-{{ $status_key }}-inactive">{{ translate('messages.Inactive') }}</label>
                                                        </div>
                                                    @endif
                                                </div>

                                                <div class="tps-input-wrap {{ $is_secret ? 'has-two-actions' : '' }}">
                                                    <input id="{{ $field_id }}" name="{{ $key }}" class="form-control"
                                                           type="{{ $is_secret ? 'password' : 'text' }}" autocomplete="off"
                                                           placeholder="{{ $key == 'otp_template' ? translate('Your Security Pin is') . ' #OTP#' : ($field_labels[$key] ?? translate($key)) }}"
                                                           value="{{ $is_demo ? '' : $value }}">
                                                    <button type="button" class="tps-input-action tps-copy"
                                                            data-target="#{{ $field_id }}" aria-label="{{ translate('Copy') }}">
                                                        <i class="tio-copy"></i>
                                                    </button>
                                                    @if ($is_secret)
                                                        <button type="button" class="tps-input-action tps-toggle-secret"
                                                                data-target="#{{ $field_id }}" aria-label="{{ translate('Show value') }}">
                                                            <i class="tio-visible"></i>
                                                        </button>
                                                    @endif
                                                </div>

                                                <div class="d-flex justify-content-between align-items-center mt-1" style="min-height: 24px;">
                                                    @if (! empty($field_hints[$key]))
                                                        <small class="tps-field__hint mb-0" style="font-size: 11px;">{{ $field_hints[$key] }}</small>
                                                    @else
                                                        <span></span>
                                                    @endif

                                                    @if ($gateway->key_name === 'custom_otp' && in_array($key, ['otp_template', 'seller_order_template', 'customer_order_template']))
                                                        <button type="button" class="btn btn-outline-info btn-xs btn-test-template flex-shrink-0 ml-2"
                                                                style="font-size: 11px; font-weight: 600; border-radius: 6px; padding: 3px 10px; white-space: nowrap;"
                                                                data-gateway="{{ $gateway->key_name }}"
                                                                data-test-type="{{ $test_type }}"
                                                                data-test-title="{{ $test_label }}"
                                                                data-title="{{ $meta['label'] }}">
                                                            <i class="tio-send mr-1"></i> {{ translate('Test') }}
                                                        </button>
                                                    @endif
                                                </div>
                                            </div>
                                        </div>
                                    @endforeach
                                </div>
                            </div>

                            <div class="tps-card__foot">
                                @if (! empty($meta['link']))
                                    <a href="{{ $meta['link'] }}" target="_blank" rel="noopener" class="tps-foot-note text--primary">
                                        <i class="tio-launch"></i> {{ translate('Open dashboard') }}
                                    </a>
                                @endif
                                <button type="button" class="btn btn-outline-info btn-test-sms"
                                        data-gateway="{{ $gateway->key_name }}"
                                        data-title="{{ $meta['label'] }}">
                                    <i class="tio-send"></i> {{ translate('Test') }}
                                </button>
                                <button type="submit" class="btn btn--primary demo_check">
                                    <i class="tio-save"></i> {{ translate('Update') }}
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            @endforeach
        </div>

        {{-- Test SMS Modal --}}
        <div class="modal fade" id="testSmsModal" tabindex="-1" role="dialog" aria-labelledby="testSmsModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title d-flex align-items-center" id="testSmsModalLabel" style="gap: 8px;">
                            <i class="tio-chat-outlined text-primary fz-20"></i>
                            <span>{{ translate('Test SMS / WhatsApp Gateway') }}</span>
                        </h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form id="testSmsForm">
                        @csrf
                        <div class="modal-body">
                            <input type="hidden" name="gateway" id="testGatewayInput">
                            <input type="hidden" name="test_type" id="testTypeInput" value="otp">

                            <div class="mb-3">
                                <label class="form-label text-capitalize font-weight-bold">
                                    {{ translate('Test Configuration') }}
                                </label>
                                <div class="alert alert-soft-primary py-2 px-3 mb-0 d-flex align-items-center justify-content-between">
                                    <div>
                                        <span id="testGatewayTitle" class="font-weight-bold d-block"></span>
                                        <small id="testTypeDesc" class="text-muted"></small>
                                    </div>
                                    <span class="badge badge-primary text-uppercase" id="testGatewayBadge"></span>
                                </div>
                            </div>

                            <div id="orderPreviewNote" class="alert alert-soft-info p-3 mb-3 d-none">
                                <div class="d-flex align-items-center font-weight-bold text-info mb-1">
                                    <i class="tio-receipt-outlined fz-16 mr-1"></i>
                                    <span id="orderPreviewTitle">{{ translate('Live Sample Order Payload') }}</span>
                                </div>
                                <div class="small text-dark">
                                    {{ translate('Dispatches live WhatsApp test using approved Meta template format with sample items (Mango 99, Mojito 49), Order ID, Store and amounts.') }}
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="testReceiverPhone" class="form-label font-weight-bold">
                                    {{ translate('Recipient Mobile Number') }} <span class="text-danger">*</span>
                                </label>
                                <input type="text" class="form-control" id="testReceiverPhone" name="receiver"
                                       placeholder="{{ translate('e.g. 919876543210 or 9876543210') }}" required autocomplete="tel">
                                <small class="form-text text-muted">
                                    <i class="tio-info-outined"></i>
                                    {{ translate('Enter mobile number with country code (e.g. 91XXXXXXXXXX). Note: WhatsApp Cloud API cannot deliver to the business sender number itself.') }}
                                </small>
                            </div>

                            <div class="form-group" id="otpInputGroup">
                                <label for="testOtpCode" class="form-label font-weight-bold">
                                    {{ translate('Test OTP Code') }} <small class="text-muted">({{ translate('Optional') }})</small>
                                </label>
                                <div class="input-group">
                                    <input type="text" class="form-control" id="testOtpCode" name="otp"
                                           placeholder="123456" maxlength="8">
                                    <div class="input-group-append">
                                        <button type="button" class="btn btn-outline-secondary" id="btnGenOtp" title="{{ translate('Generate random OTP') }}">
                                            <i class="tio-refresh"></i> {{ translate('Generate') }}
                                        </button>
                                    </div>
                                </div>
                                <small class="form-text text-muted">
                                    {{ translate('Leave blank to use a randomly generated 6-digit OTP.') }}
                                </small>
                            </div>

                            <div id="testSmsAlert" class="d-none"></div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-dismiss="modal">
                                {{ translate('Close') }}
                            </button>
                            <button type="submit" class="btn btn--primary" id="btnSendTestSms">
                                <span class="spinner-border spinner-border-sm d-none mr-1" id="testSmsSpinner" role="status" aria-hidden="true"></span>
                                <i class="tio-send mr-1" id="testSmsIcon"></i>
                                <span id="btnSendTestText">{{ translate('Send Test OTP') }}</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
@endsection

@push('script_2')
    @include('admin-views.business-settings.partials.third-party-scripts')
    <script>
        $(document).on('click', '.btn-test-sms', function () {
            const gateway = $(this).data('gateway');
            const title = $(this).data('title');

            $('#testGatewayInput').val(gateway);
            $('#testTypeInput').val('otp');
            $('#testGatewayTitle').text(title);
            $('#testGatewayBadge').text(gateway);
            $('#testTypeDesc').text('{{ translate("Testing general OTP verification delivery") }}');
            $('#otpInputGroup').removeClass('d-none');
            $('#orderPreviewNote').addClass('d-none');
            $('#btnSendTestText').text('{{ translate("Send Test OTP") }}');
            $('#testOtpCode').val(Math.floor(100000 + Math.random() * 900000));
            $('#testSmsAlert').addClass('d-none').html('');
            $('#testReceiverPhone').val('');
            $('#testSmsModal').modal('show');
        });

        $(document).on('click', '.btn-test-template', function () {
            const gateway = $(this).data('gateway');
            const title = $(this).data('title');
            const testType = $(this).data('test-type');
            const testTitle = $(this).data('test-title');

            $('#testGatewayInput').val(gateway);
            $('#testTypeInput').val(testType);
            $('#testGatewayTitle').text(title);
            $('#testGatewayBadge').text(testTitle);

            if (testType === 'otp') {
                $('#otpInputGroup').removeClass('d-none');
                $('#orderPreviewNote').addClass('d-none');
                $('#testTypeDesc').text('{{ translate("Testing OTP verification delivery") }}');
                $('#btnSendTestText').text('{{ translate("Send Test OTP") }}');
                $('#testOtpCode').val(Math.floor(100000 + Math.random() * 900000));
            } else if (testType === 'seller_order') {
                $('#otpInputGroup').addClass('d-none');
                $('#orderPreviewNote').removeClass('d-none');
                $('#testTypeDesc').text('{{ translate("Testing Seller Order Alert template via Meta WhatsApp") }}');
                $('#orderPreviewTitle').text('{{ translate("Seller Order Alert Template Test") }}');
                $('#btnSendTestText').text('{{ translate("Send Test Seller Alert") }}');
            } else if (testType === 'customer_order') {
                $('#otpInputGroup').addClass('d-none');
                $('#orderPreviewNote').removeClass('d-none');
                $('#testTypeDesc').text('{{ translate("Testing Customer Order Alert template via Meta WhatsApp") }}');
                $('#orderPreviewTitle').text('{{ translate("Customer Order Alert Template Test") }}');
                $('#btnSendTestText').text('{{ translate("Send Test Customer Alert") }}');
            }

            $('#testSmsAlert').addClass('d-none').html('');
            $('#testReceiverPhone').val('');
            $('#testSmsModal').modal('show');
        });

        $('#btnGenOtp').on('click', function () {
            $('#testOtpCode').val(Math.floor(100000 + Math.random() * 900000));
        });

        $('#testSmsForm').on('submit', function (e) {
            e.preventDefault();

            const receiver = $('#testReceiverPhone').val().trim();
            if (!receiver) {
                if (typeof toastr !== 'undefined') {
                    toastr.error('{{ translate("Please enter recipient mobile number") }}');
                }
                return;
            }

            const $btn = $('#btnSendTestSms');
            const $spinner = $('#testSmsSpinner');
            const $icon = $('#testSmsIcon');
            const $alert = $('#testSmsAlert');

            $btn.prop('disabled', true);
            $spinner.removeClass('d-none');
            $icon.addClass('d-none');
            $alert.addClass('d-none').html('');

            $.ajax({
                url: '{{ route("admin.business-settings.third-party.sms-test") }}',
                method: 'POST',
                data: $(this).serialize(),
                headers: {
                    'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                },
                success: function (res) {
                    if (res && res.success) {
                        const successTitle = res.message || '{{ translate("Test OTP dispatched successfully!") }}';
                        let html = '<div class="test-sms-result alert alert-soft-success p-3 mb-0">';
                        html += '<div class="d-flex align-items-center mb-1 text-success font-weight-bold">';
                        html += '<i class="tio-checkmark-circle-outlined fz-18 mr-2"></i>';
                        html += '<span>' + successTitle + '</span>';
                        html += '</div>';
                        if (res.otp) {
                            html += '<div class="mt-2 small text-dark"><strong>{{ translate("Sent OTP Code") }}:</strong> <span class="badge badge-success px-2 py-1 ml-1 fz-12">' + res.otp + '</span></div>';
                        }
                        if (res.provider_message_id) {
                            html += '<div class="mt-2 small text-muted"><strong>{{ translate("Provider Message ID") }}:</strong><code class="d-block mt-1 p-2 bg-white border rounded text-dark font-mono">' + res.provider_message_id + '</code></div>';
                        }
                        html += '</div>';

                        $alert.removeClass('d-none').html(html);
                        if (typeof toastr !== 'undefined') {
                            toastr.success(successTitle);
                        }
                    } else {
                        const errText = (res && res.message) ? res.message : '{{ translate("Failed to send OTP.") }}';
                        let errHtml = '<div class="test-sms-result alert alert-soft-danger p-3 mb-0">';
                        errHtml += '<div class="d-flex align-items-center mb-1 text-danger font-weight-bold">';
                        errHtml += '<i class="tio-error-outlined fz-18 mr-2"></i>';
                        errHtml += '<span>{{ translate("Failed to dispatch OTP") }}</span>';
                        errHtml += '</div>';
                        errHtml += '<div class="small text-danger mt-1">' + errText + '</div>';
                        errHtml += '</div>';

                        $alert.removeClass('d-none').html(errHtml);
                        if (typeof toastr !== 'undefined') {
                            toastr.error('{{ translate("Failed to send test OTP") }}');
                        }
                    }
                },
                error: function (xhr) {
                    let errorMsg = '{{ translate("Something went wrong while dispatching test OTP.") }}';
                    if (xhr.responseJSON && xhr.responseJSON.message) {
                        errorMsg = xhr.responseJSON.message;
                    }
                    let errHtml = '<div class="test-sms-result alert alert-soft-danger p-3 mb-0">';
                    errHtml += '<div class="d-flex align-items-center mb-1 text-danger font-weight-bold">';
                    errHtml += '<i class="tio-error-outlined fz-18 mr-2"></i>';
                    errHtml += '<span>{{ translate("Error") }}</span>';
                    errHtml += '</div>';
                    errHtml += '<div class="small text-danger mt-1">' + errorMsg + '</div>';
                    errHtml += '</div>';

                    $alert.removeClass('d-none').html(errHtml);
                    if (typeof toastr !== 'undefined') {
                        toastr.error(errorMsg);
                    }
                },
                complete: function () {
                    $btn.prop('disabled', false);
                    $spinner.addClass('d-none');
                    $icon.removeClass('d-none');
                }
            });
        });
    </script>
@endpush

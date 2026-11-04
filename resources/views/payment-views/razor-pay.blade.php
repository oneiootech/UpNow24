@extends('payment-views.layouts.master')


@section('content')
    <div class="razorpay-container">
        <h1 class="text-center">{{ "Please do not refresh this page..." }}</h1>

        <div id="razorpay-error-box" style="display:none; color: #dc3545; background-color: #f8d7da; border: 1px solid #f5c6cb; padding: 12px 20px; border-radius: 6px; max-width: 90%; text-align: center; margin: 10px auto; font-size: 14px; font-weight: 500;"></div>

        <div class="razorpay-button-container">
            <button type="button" id="rzp-button1">Pay</button>
            <button type="button" class="razorpay-cancel-button" id="razorpay-cancel-button">Cancel</button>
        </div>
    </div>

    <script type="text/javascript">
        "use strict";
        document.getElementById('razorpay-cancel-button').onclick = function () {
            window.location.href = '{{ route('razor-pay.cancel', ['payment_id' => $data->id]) }}';
        };
    </script>
@endsection

@push('script')
    <style>
        .razorpay-container {
            display: flex;
            justify-content: center;
            align-items: center;
            flex-direction: column;
            min-height: 100vh;
            gap: 1rem;
        }

        .razorpay-button-container {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 1rem;
        }

        .razorpay-button-container button {
            --background-color: 69, 160, 73;
            --background-opacity: .8;
            background-color: rgba(var(--background-color), var(--background-opacity));
            color: white;
            border: none;
            padding: .5rem 2.5rem;
            font-size: .85rem;
            cursor: pointer;
            border-radius: 5px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
        }

        .razorpay-button-container button:last-child {
            --background-color: 235, 20, 20;
        }

        .razorpay-button-container button:hover,
        .razorpay-button-container button:focus {
            outline: none;
            --background-opacity: 1;
            box-shadow: 0 6px 12px rgba(0, 0, 0, 0.2);
        }
    </style>

    <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function () {
            let rzpButton = document.getElementById('rzp-button1');
            let errorBox = document.getElementById('razorpay-error-box');

            function showError(msg) {
                if (errorBox) {
                    errorBox.innerText = msg;
                    errorBox.style.display = 'block';
                }
                console.error("Razorpay Error:", msg);
            }

            if (rzpButton) {
                rzpButton.innerText = "Initializing...";
                rzpButton.disabled = true;

                fetch("{{ route('razor-pay.create-order') }}", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "X-CSRF-TOKEN": "{{ csrf_token() }}"
                    },
                    body: JSON.stringify({
                        payment_request_id: "{{ $data->id }}",
                        payment_amount: "{{ $data->payment_amount }}",
                        currency_code: "{{ $data->currency_code }}"
                    })
                })
                .then(response => response.json())
                .then(orderData => {
                    if (!orderData.status || !orderData.order_id) {
                        let err = orderData.message || "Unable to initialize Razorpay checkout.";
                        showError(err);
                        rzpButton.innerText = "Retry";
                        rzpButton.disabled = false;
                        rzpButton.onclick = function() { location.reload(); };
                        return;
                    }

                    var options = {
                        "key": "{{ config()->get('razor_config.api_key') }}",
                        "amount": orderData.amount,
                        "currency": orderData.currency,
                        "name": "{{ $business_name }}",
                        "description": "{{ $data->payment_amount }}",
                        "image": "{{ $business_logo }}",
                        "order_id": orderData.order_id,
                        "webview_intent": true,
                        "callback_url": "{{ route('razor-pay.callback', ['payment_data' => base64_encode($data->id)])  }}",
                        "handler": function (response) {
                            console.log("Payment successful!", response);
                            window.location.href = "{{ route('razor-pay.verify-payment') }}?" + new URLSearchParams({
                                payment_request_id: "{{ $data->id }}",
                                payment_id: response.razorpay_payment_id,
                                order_id: response.razorpay_order_id,
                                signature: response.razorpay_signature
                            }).toString();
                        },
                        "prefill": {
                            "name": "{{ $payer?->name ?? '' }}",
                            "email": "{{ $payer?->email ?? '' }}",
                            "contact": "{{ $payer?->phone ?? '' }}"
                        },
                        "readonly": {
                            "contact": true,
                            "email": true,
                            "name": true
                        },
                        "modal": {
                            "ondismiss": function () {
                                window.location.href = '{{ route('razor-pay.cancel', ['payment_id' => $data->id]) }}';
                            }
                        },
                        "theme": {
                            "color": "#ff7529"
                        }
                    };
                    var rzp1 = new Razorpay(options);

                    rzpButton.innerText = "Pay";
                    rzpButton.disabled = false;

                    rzpButton.onclick = function (e) {
                        rzp1.open();
                        e.preventDefault();
                    };

                    // Auto-open razorpay popup
                    try {
                        rzp1.open();
                    } catch (e) {
                        console.error("Auto open failed:", e);
                    }
                })
                .catch(error => {
                    showError(error.message || "Something went wrong connecting to payment gateway.");
                    rzpButton.innerText = "Retry";
                    rzpButton.disabled = false;
                    rzpButton.onclick = function() { location.reload(); };
                });
            }
        });
    </script>
@endpush

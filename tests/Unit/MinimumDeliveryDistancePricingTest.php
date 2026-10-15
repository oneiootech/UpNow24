<?php

namespace Tests\Unit;

use App\Models\BusinessSetting;
use App\Models\DeliveryRule;
use App\Services\Order\DeliveryChargeService;
use App\Services\System\DistanceService;
use App\Services\Zone\DeliveryRuleService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

/**
 * G DELIVERS — DELIVERY PRICING ENGINE ENHANCEMENT
 *
 * Validation tests covering:
 * 1. Base Distance + Excess Distance formula (Section 8 spec)
 * 2. Decimal distances
 * 3. KM/Miles conversion
 * 4. Invalid negative values
 * 5. Zero or disabled maximum cap
 * 6. Parcel additional tier charges
 * 7. Surge pricing after maximum cap
 * 8. Legacy rules backward compatibility
 * 9. Default zone pivot fallback
 * 10. Vendor self-delivery priority
 * 11. Module-specific rule selection
 */
class MinimumDeliveryDistancePricingTest extends TestCase
{
    use DatabaseTransactions;

    private DeliveryChargeService $engine;

    private DeliveryRuleService $rules;

    private int $zoneId;

    private int $moduleId;

    protected function setUp(): void
    {
        parent::setUp();

        $this->engine = app(DeliveryChargeService::class);
        $this->rules = app(DeliveryRuleService::class);
        $this->zoneId = (int) \DB::table('zones')->value('id');
        $this->moduleId = (int) \DB::table('modules')->value('id');

        app(DistanceService::class)->forgetUnit();
    }

    protected function tearDown(): void
    {
        app(DistanceService::class)->forgetUnit();
        parent::tearDown();
    }

    private function activateRule(array $attributes): DeliveryRule
    {
        $rule = $this->rules->create($attributes + [
            'zone_id' => $this->zoneId,
            'module_ids' => [$this->moduleId],
            'name' => 'Spec Test ' . uniqid(),
            'status' => true,
        ]);

        $this->rules->updateStatus($rule->id, 1);

        return $rule->refresh();
    }

    private function specRule(array $overrides = []): DeliveryRule
    {
        return $this->activateRule($overrides + [
            'pricing_method' => DeliveryRule::METHOD_DISTANCE,
            'delivery_pricing_method' => DeliveryRule::DISTANCE_METHOD_BASE_EXCESS,
            'minimum_delivery_charge' => 20.0,
            'minimum_delivery_distance' => 3.0,
            'per_km_charge' => 10.0,
            'maximum_delivery_charge' => 150.0,
        ]);
    }

    /**
     * Section 8 validation cases:
     * Minimum Charge: ₱20
     * Minimum Distance: 3 km
     * Per Unit Charge: ₱10/km
     * Maximum Charge: ₱150
     *
     * Expected results before additional charges:
     * 1 km = ₱20
     * 3 km = ₱20
     * 4 km = ₱30
     * 5 km = ₱40
     * 8 km = ₱70
     * 20 km = ₱150
     */
    public function test_spec_validation_cases_for_base_excess_pricing(): void
    {
        $this->specRule();

        $cases = [
            1.0 => 20.0,
            3.0 => 20.0,
            4.0 => 30.0,
            5.0 => 40.0,
            8.0 => 70.0,
            20.0 => 150.0, // 20 + (20-3)*10 = 190, clamped to max 150
        ];

        foreach ($cases as $km => $expectedFee) {
            $quote = $this->engine->quote([
                'order_type' => 'delivery',
                'distance' => (float) $km,
                'zone_id' => $this->zoneId,
                'module_id' => $this->moduleId,
            ]);

            $this->assertEqualsWithDelta(
                $expectedFee,
                $quote['base_delivery_charge'],
                0.0001,
                "Failed at distance {$km} km: expected {$expectedFee}, got {$quote['base_delivery_charge']}"
            );

            $this->assertEqualsWithDelta(
                $expectedFee,
                $quote['delivery_charge'],
                0.0001,
                "Delivery charge failed at distance {$km} km"
            );

            $this->assertSame(DeliveryChargeService::SOURCE_DELIVERY_RULE, $quote['pricing_source']);
            $this->assertSame(20.0, $quote['floor']);
        }
    }

    public function test_decimal_distances_and_precision(): void
    {
        $this->specRule();

        // At 3.5 km: Excess = 0.5 km. Fee = 20 + 0.5 * 10 = 25.0
        $quote35 = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => 3.5,
            'zone_id' => $this->zoneId,
            'module_id' => $this->moduleId,
        ]);
        $this->assertEqualsWithDelta(25.0, $quote35['base_delivery_charge'], 0.0001);

        // At 4.25 km: Excess = 1.25 km. Fee = 20 + 1.25 * 10 = 32.50
        $quote425 = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => 4.25,
            'zone_id' => $this->zoneId,
            'module_id' => $this->moduleId,
        ]);
        $this->assertEqualsWithDelta(32.50, $quote425['base_delivery_charge'], 0.0001);

        // At 2.75 km: Excess = 0. Fee = 20.0
        $quote275 = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => 2.75,
            'zone_id' => $this->zoneId,
            'module_id' => $this->moduleId,
        ]);
        $this->assertEqualsWithDelta(20.0, $quote275['base_delivery_charge'], 0.0001);
    }

    public function test_invalid_negative_or_zero_distances(): void
    {
        $this->specRule();

        // 0 km
        $quote0 = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => 0.0,
            'zone_id' => $this->zoneId,
            'module_id' => $this->moduleId,
        ]);
        $this->assertEqualsWithDelta(20.0, $quote0['base_delivery_charge'], 0.0001);

        // Negative distance sanitized to 0
        $quoteNeg = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => -10.0,
            'zone_id' => $this->zoneId,
            'module_id' => $this->moduleId,
        ]);
        $this->assertEqualsWithDelta(20.0, $quoteNeg['base_delivery_charge'], 0.0001);
    }

    public function test_zero_or_disabled_maximum_cap(): void
    {
        // Max charge = 0 means NO CAP
        $this->specRule(['maximum_delivery_charge' => 0.0]);

        $quote = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => 20.0,
            'zone_id' => $this->zoneId,
            'module_id' => $this->moduleId,
        ]);

        // 20 + (20 - 3) * 10 = 190.0 (unclamped)
        $this->assertEqualsWithDelta(190.0, $quote['base_delivery_charge'], 0.0001);

        // Null maximum also means NO CAP
        $this->specRule(['maximum_delivery_charge' => null]);

        $quoteNull = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => 20.0,
            'zone_id' => $this->zoneId,
            'module_id' => $this->moduleId,
        ]);

        $this->assertEqualsWithDelta(190.0, $quoteNull['base_delivery_charge'], 0.0001);
    }

    public function test_surge_pricing_applied_after_maximum_cap(): void
    {
        $this->specRule();

        // At 20 km, base fee is 190 clamped to max 150.
        // With a 20% surge, surge applies to the clamped 150 => 150 * 20% = 30.
        // Total delivery charge = 150 + 30 = 180.
        $quote = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => 20.0,
            'zone_id' => $this->zoneId,
            'module_id' => $this->moduleId,
            'surge' => ['price' => 20.0, 'price_type' => 'percent'],
        ]);

        $this->assertEqualsWithDelta(150.0, $quote['base_delivery_charge'], 0.0001);
        $this->assertEqualsWithDelta(30.0, $quote['surge_amount'], 0.0001);
        $this->assertEqualsWithDelta(180.0, $quote['delivery_charge'], 0.0001);
    }

    public function test_existing_legacy_rules_preserve_legacy_behavior(): void
    {
        // Legacy distance rule: Base Fee = MAX(Distance * Per Unit Rate, Minimum Charge)
        $this->activateRule([
            'pricing_method' => DeliveryRule::METHOD_DISTANCE,
            'delivery_pricing_method' => DeliveryRule::DISTANCE_METHOD_LEGACY,
            'minimum_delivery_charge' => 20.0,
            'per_km_charge' => 10.0,
            'maximum_delivery_charge' => 150.0,
        ]);

        $cases = [
            1.0 => 20.0, // MAX(10, 20) = 20
            3.0 => 30.0, // MAX(30, 20) = 30
            4.0 => 40.0, // MAX(40, 20) = 40
            5.0 => 50.0, // MAX(50, 20) = 50
            8.0 => 80.0, // MAX(80, 20) = 80
            20.0 => 150.0, // MAX(200, 20) = 200, clamped to 150
        ];

        foreach ($cases as $km => $expectedFee) {
            $quote = $this->engine->quote([
                'order_type' => 'delivery',
                'distance' => (float) $km,
                'zone_id' => $this->zoneId,
                'module_id' => $this->moduleId,
            ]);

            $this->assertEqualsWithDelta(
                $expectedFee,
                $quote['base_delivery_charge'],
                0.0001,
                "Legacy rule diverged at {$km} km"
            );
        }
    }

    public function test_default_zone_pivot_fallback_uses_legacy_distance_calculation(): void
    {
        // When no active rule matches, pivot is used
        $pivot = (object) [
            'zone_id' => $this->zoneId,
            'module_id' => 99999, // Unmatched module
            'delivery_charge_type' => 'distance',
            'per_km_shipping_charge' => 10.0,
            'minimum_shipping_charge' => 20.0,
            'maximum_shipping_charge' => 150.0,
        ];

        $quote = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => 4.0,
            'module_zone_pivot' => $pivot,
        ]);

        $this->assertSame(DeliveryChargeService::SOURCE_MODULE_ZONE, $quote['pricing_source']);
        // Legacy calculation: MAX(4 * 10, 20) = 40.0
        $this->assertEqualsWithDelta(40.0, $quote['base_delivery_charge'], 0.0001);
    }

    public function test_vendor_self_delivery_outranks_delivery_rule(): void
    {
        $this->specRule();

        $store = (object) [
            'sub_self_delivery' => 1,
            'per_km_shipping_charge' => 5.0,
            'minimum_shipping_charge' => 15.0,
            'maximum_shipping_charge' => 100.0,
        ];

        $quote = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => 4.0,
            'store' => $store,
            'zone_id' => $this->zoneId,
            'module_id' => $this->moduleId,
        ]);

        $this->assertSame(DeliveryChargeService::SOURCE_SELF_DELIVERY, $quote['pricing_source']);
        // Vendor self-delivery: MAX(4 * 5, 15) = 20.0
        $this->assertEqualsWithDelta(20.0, $quote['base_delivery_charge'], 0.0001);
    }

    public function test_distance_unit_conversion_miles_and_km(): void
    {
        \DB::table('business_settings')->updateOrInsert(['key' => 'distance_unit'], ['value' => 'mi']);
        \App\CentralLogics\Helpers::clearBusinessSettingsCache();
        app(DistanceService::class)->forgetUnit();

        $distanceService = app(DistanceService::class);
        $this->assertSame('mi', $distanceService->unit());

        // Trip of 8.0 km, minimum distance 3.0 km, per-unit rate 10/mi, minimum fee 20
        $feeInMiles = $this->engine->chargeableBase(
            distanceKm: 8.0,
            perUnit: 10.0,
            minimum: 20.0,
            flat: null,
            pricingMethod: DeliveryRule::DISTANCE_METHOD_BASE_EXCESS,
            minimumDistanceKm: 3.0
        );

        $chargeable8 = $distanceService->chargeable(8.0);
        $chargeable3 = $distanceService->chargeable(3.0);
        $expectedExcess = max(0.0, $chargeable8 - $chargeable3);
        $expectedFee = 20.0 + ($expectedExcess * 10.0);

        $this->assertEqualsWithDelta($expectedFee, $feeInMiles, 0.0001);

        // Reset to km
        \DB::table('business_settings')->updateOrInsert(['key' => 'distance_unit'], ['value' => 'km']);
        \App\CentralLogics\Helpers::clearBusinessSettingsCache();
        app(DistanceService::class)->forgetUnit();
    }

    public function test_module_specific_rule_selection(): void
    {
        $otherModuleId = (int) \DB::table('modules')->where('id', '!=', $this->moduleId)->value('id');
        if (! $otherModuleId) {
            $otherModuleId = (int) \DB::table('modules')->insertGetId([
                'module_name' => 'Module 2 ' . uniqid(),
                'module_type' => 'pharmacy',
                'theme_id' => 1,
                'status' => 1,
                'slug' => 'module-2-' . uniqid(),
            ]);
        }

        \DB::table('module_zone')->updateOrInsert(
            ['module_id' => $otherModuleId, 'zone_id' => $this->zoneId],
            ['per_km_shipping_charge' => 5, 'minimum_shipping_charge' => 15, 'maximum_shipping_charge' => 100]
        );

        // Rule 1 for moduleId: Base Distance + Excess Distance (min 20, min dist 3, per km 10, max 150)
        $this->specRule();

        // Rule 2 for otherModuleId: Legacy Distance (min 15, per km 5, max 100)
        $this->rules->create([
            'zone_id' => $this->zoneId,
            'module_ids' => [$otherModuleId],
            'name' => 'Module 2 Legacy ' . uniqid(),
            'pricing_method' => DeliveryRule::METHOD_DISTANCE,
            'delivery_pricing_method' => DeliveryRule::DISTANCE_METHOD_LEGACY,
            'minimum_delivery_charge' => 15.0,
            'per_km_charge' => 5.0,
            'maximum_delivery_charge' => 100.0,
            'status' => true,
        ]);

        // At 5 km:
        // Module 1: Base Excess = 20 + (5-3)*10 = 40.0
        $quote1 = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => 5.0,
            'zone_id' => $this->zoneId,
            'module_id' => $this->moduleId,
        ]);
        $this->assertEqualsWithDelta(40.0, $quote1['base_delivery_charge'], 0.0001);

        // Module 2: Legacy = MAX(5*5, 15) = 25.0
        $quote2 = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => 5.0,
            'zone_id' => $this->zoneId,
            'module_id' => $otherModuleId,
        ]);
        $this->assertEqualsWithDelta(25.0, $quote2['base_delivery_charge'], 0.0001);
    }

    public function test_parcel_additional_charges_with_base_excess(): void
    {
        $parcelModuleId = (int) \DB::table('modules')->where('module_type', 'parcel')->value('id');
        if (! $parcelModuleId) {
            $parcelModuleId = (int) \DB::table('modules')->insertGetId([
                'module_name' => 'Parcel ' . uniqid(),
                'module_type' => 'parcel',
                'theme_id' => 1,
                'status' => 1,
                'slug' => 'parcel-' . uniqid(),
            ]);
        }

        \DB::table('module_zone')->updateOrInsert(
            ['module_id' => $parcelModuleId, 'zone_id' => $this->zoneId],
            ['per_km_shipping_charge' => 10, 'minimum_shipping_charge' => 20, 'maximum_shipping_charge' => 150]
        );

        $rule = $this->rules->create([
            'zone_id' => $this->zoneId,
            'module_ids' => [$parcelModuleId],
            'name' => 'Parcel Spec ' . uniqid(),
            'pricing_method' => DeliveryRule::METHOD_DISTANCE,
            'delivery_pricing_method' => DeliveryRule::DISTANCE_METHOD_BASE_EXCESS,
            'minimum_delivery_charge' => 20.0,
            'minimum_delivery_distance' => 3.0,
            'per_km_charge' => 10.0,
            'maximum_delivery_charge' => 150.0,
            'status' => true,
        ]);
        $this->rules->updateStatus($rule->id, 1);

        // Category charge = 25 flat
        $category = new \App\Models\ParcelCategory;
        $category->forceFill([
            'name' => 'Box',
            'charge' => 25.0,
            'status' => 1,
            'module_id' => $parcelModuleId,
        ]);
        $category->save();

        // At 4 km:
        // Base distance fee = 20 + (4-3)*10 = 30.0
        // Tier category fee = +25.0
        // Total = 55.0
        $quote = $this->engine->quote([
            'order_type' => 'parcel',
            'distance' => 4.0,
            'zone_id' => $this->zoneId,
            'module_id' => $parcelModuleId,
            'parcel_category_id' => $category->id,
        ]);

        $this->assertEqualsWithDelta(55.0, $quote['base_delivery_charge'], 0.0001);
        $this->assertEqualsWithDelta(55.0, $quote['delivery_charge'], 0.0001);
    }


    public function test_free_delivery_waives_base_excess_fee(): void
    {
        $this->specRule();

        // Standard 5 km delivery fee is 40.0
        $quote = $this->engine->quote([
            'order_type' => 'delivery',
            'distance' => 5.0,
            'zone_id' => $this->zoneId,
            'module_id' => $this->moduleId,
        ]);
        $this->assertEqualsWithDelta(40.0, $quote['base_delivery_charge'], 0.0001);

        // Applying DeliveryFeeTrait free delivery (e.g. store free_delivery = 1)
        $trait = new class {
            use \App\Traits\Order\DeliveryFeeTrait;
        };

        $result = $trait->effectiveFee(
            baseFee: $quote['delivery_charge'],
            store: (object) ['free_delivery' => 1, 'id' => 1, 'zone_id' => $this->zoneId, 'module_id' => $this->moduleId],
            eligibleOrderAmount: 500.0,
            couponCode: null,
        );

        $this->assertTrue($result['is_free']);
        $this->assertSame(0.0, $result['fee']);
        $this->assertSame('vendor', $result['free_by']);
    }
}




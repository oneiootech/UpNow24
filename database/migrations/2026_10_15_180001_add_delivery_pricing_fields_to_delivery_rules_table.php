<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Adds support for the configurable Minimum Delivery Distance pricing method
     * ("Base Distance + Excess Distance") while preserving the default legacy distance calculation.
     */
    public function up(): void
    {
        Schema::table('delivery_rules', function (Blueprint $table) {
            $table->string('delivery_pricing_method', 30)->nullable()->default('legacy_distance')->after('pricing_method')
                ->comment('legacy_distance | base_excess');
            $table->decimal('minimum_delivery_distance', 10, 2)->nullable()->after('delivery_pricing_method')
                ->comment('Base distance included in minimum delivery charge in km');
        });

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('delivery_rules', function (Blueprint $table) {
            $table->dropColumn(['delivery_pricing_method', 'minimum_delivery_distance']);
        });
    }
};

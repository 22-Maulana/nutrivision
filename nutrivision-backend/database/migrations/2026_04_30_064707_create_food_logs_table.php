<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('food_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained('users')->onDelete('cascade');
            $table->enum('target_type', ['MOTHER', 'CHILD']);
            $table->uuid('target_id');
            $table->dateTime('meal_time');
            $table->string('photo_url')->nullable();
            $table->string('food_name_detected');
            $table->text('notes')->nullable();
            $table->string('recommendation_status');
            $table->float('calories_kcal')->default(0);
            $table->float('protein_g')->default(0);
            $table->float('fat_g')->default(0);
            $table->float('carbs_g')->default(0);
            $table->float('fiber_g')->default(0);
            $table->float('iron_mg')->default(0);
            $table->float('calcium_mg')->default(0);
            $table->timestamps();

            $table->index(['user_id', 'meal_time']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('food_logs');
    }
};

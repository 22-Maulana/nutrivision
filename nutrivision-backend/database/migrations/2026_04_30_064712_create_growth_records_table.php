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
        Schema::create('growth_records', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('target_type'); // MOTHER or CHILD
            $table->uuid('target_id');
            $table->date('measured_at');
            $table->float('weight_kg');
            $table->float('height_cm');
            $table->string('status')->default('Normal');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('growth_records');
    }
};

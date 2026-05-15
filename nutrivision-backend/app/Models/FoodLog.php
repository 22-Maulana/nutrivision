<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable([
    'user_id', 'target_type', 'target_id', 'meal_time', 'photo_url', 
    'food_name_detected', 'notes', 'recommendation_status', 
    'calories_kcal', 'protein_g', 'fat_g', 'carbs_g', 'fiber_g', 'iron_mg', 'calcium_mg'
])]
class FoodLog extends Model
{
    use HasFactory, HasUuids;

    protected function casts(): array
    {
        return [
            'meal_time' => 'datetime',
        ];
    }
}

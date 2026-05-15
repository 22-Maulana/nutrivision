<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['target_type', 'target_id', 'measured_at', 'weight_kg', 'height_cm', 'status'])]
class GrowthRecord extends Model
{
    use HasFactory, HasUuids;

    protected function casts(): array
    {
        return [
            'measured_at' => 'date',
        ];
    }
}

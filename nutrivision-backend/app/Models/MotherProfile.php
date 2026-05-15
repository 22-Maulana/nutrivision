<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['user_id', 'full_name', 'birth_date', 'status', 'allergies'])]
class MotherProfile extends Model
{
    use HasFactory, HasUuids;

    protected function casts(): array
    {
        return [
            'allergies' => 'array',
            'birth_date' => 'date',
        ];
    }
}

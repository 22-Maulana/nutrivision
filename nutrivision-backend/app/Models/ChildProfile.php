<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['user_id', 'name', 'birth_date', 'gender', 'allergies'])]
class ChildProfile extends Model
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

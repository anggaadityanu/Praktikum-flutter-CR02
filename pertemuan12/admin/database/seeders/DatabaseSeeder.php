<?php

namespace Database\Seeders;

use App\Models\Admin;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /** Aman dijalankan berulang: admin yang sama tidak dibuat dua kali. */
    public function run(): void
    {
        Admin::firstOrCreate(
            ['email' => env('ADMIN_EMAIL', 'admin@tabungku.test')],
            [
                'name' => 'Administrator',
                'password' => env('ADMIN_PASSWORD', 'admin12345'),
            ],
        );
    }
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Pengguna aplikasi mobile. Tabel `users` dibuat dan dimigrasi oleh
 * Alembic (FastAPI), jadi TIDAK ada migrasi Laravel untuk tabel ini.
 */
class Pengguna extends Model
{
    protected $table = 'users';

    // Tabel users hanya punya created_at (tanpa updated_at).
    const UPDATED_AT = null;

    protected $fillable = ['nama', 'target_harian', 'aktif'];

    protected $hidden = ['password_hash'];

    protected function casts(): array
    {
        return [
            'aktif' => 'boolean',
            'target_harian' => 'integer',
        ];
    }

    public function kegiatan(): HasMany
    {
        return $this->hasMany(Kegiatan::class, 'user_id');
    }
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/** Kategori pengeluaran. Tabel `kategori` dimiliki Alembic. */
class Kategori extends Model
{
    protected $table = 'kategori';

    protected $fillable = ['nama', 'urutan', 'aktif'];

    protected function casts(): array
    {
        return [
            'aktif' => 'boolean',
            'urutan' => 'integer',
        ];
    }

    public function kegiatan(): HasMany
    {
        return $this->hasMany(Kegiatan::class, 'kategori_id');
    }
}
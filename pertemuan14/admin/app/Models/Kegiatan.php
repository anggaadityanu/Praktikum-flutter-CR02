<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Kegiatan milik pengguna. Tabel `kegiatan` dimiliki Alembic. */
class Kegiatan extends Model
{
    protected $table = 'kegiatan';

    protected $fillable = [
        'user_id', 'judul', 'tanggal', 'selesai', 'tipe', 'nominal', 'kategori_id',
    ];

    protected function casts(): array
    {
        return [
            'tanggal' => 'date',
            'selesai' => 'boolean',
            'nominal' => 'integer',
        ];
    }

    public function pengguna(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'user_id');
    }

    public function kategori(): BelongsTo
    {
        return $this->belongsTo(Kategori::class, 'kategori_id');
    }

        /** URL lengkap foto bukti, disajikan oleh FastAPI di /uploads. */
    public function buktiUrl(): ?string
    {
        return $this->bukti
            ? rtrim(config('services.tabungku_api.url'), '/').'/'.$this->bukti
            : null;
    }
}
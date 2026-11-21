<?php

namespace App\Filament\Widgets;

use App\Models\Kegiatan;
use Filament\Widgets\ChartWidget;

/** Diagram donat: kategori mana yang paling banyak menghabiskan uang. */
class PengeluaranPerKategoriChart extends ChartWidget
{
    protected static ?int $sort = 2;

    protected ?string $heading = 'Pengeluaran per kategori';

    protected ?string $maxHeight = '280px';

    // Pilihan rentang di pojok kanan atas widget.
    public ?string $filter = '30';

    protected function getFilters(): ?array
    {
        return [
            '7' => '7 hari',
            '30' => '30 hari',
            '365' => '1 tahun',
        ];
    }

    protected function getData(): array
    {
        $baris = Kegiatan::query()
            ->join('kategori', 'kategori.id', '=', 'kegiatan.kategori_id')
            ->where('kegiatan.tipe', 'pengeluaran')
            ->whereDate('kegiatan.tanggal', '>=', today()->subDays((int) $this->filter - 1))
            ->groupBy('kategori.nama')
            ->orderByDesc('total')
            ->selectRaw('kategori.nama AS nama, SUM(kegiatan.nominal) AS total')
            ->get();

        return [
            'datasets' => [
                [
                    'label' => 'Pengeluaran (Rp)',
                    'data' => $baris->pluck('total')->map(fn ($t) => (int) $t)->all(),
                    // Palet yang sama dengan pilihan warna di aplikasi TabungKu.
                    'backgroundColor' => ['#6C4CF1', '#10B981', '#F97316', '#E11D48', '#0EA5E9', '#64748B', '#A78BFA'],
                ],
            ],
            'labels' => $baris->pluck('nama')->all(),
        ];
    }

    protected function getType(): string
    {
        return 'doughnut';
    }
}
<?php

namespace App\Filament\Resources\Kegiatans;

use App\Filament\Resources\Kegiatans\Pages\ManageKegiatans;
use App\Models\Kegiatan;
use BackedEnum;
use Filament\Actions\DeleteAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\DatePicker;
use Filament\Infolists\Components\IconEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

/** Kegiatan dicatat dari aplikasi mobile; admin hanya melihat dan menghapus. */
class KegiatanResource extends Resource
{
    protected static ?string $model = Kegiatan::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedBanknotes;

    protected static ?string $navigationLabel = 'Riwayat Kegiatan';

    protected static ?string $recordTitleAttribute = 'judul';

    protected static ?string $modelLabel = 'kegiatan';

    protected static ?string $pluralModelLabel = 'kegiatan';

    protected static ?int $navigationSort = 1;

    public const TIPE = [
        'tanpa' => 'Tanpa uang',
        'pemasukan' => 'Pemasukan',
        'pengeluaran' => 'Pengeluaran',
    ];

    public static function canCreate(): bool
    {
        return false;
    }

    public static function infolist(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextEntry::make('judul'),
                TextEntry::make('tanggal')->date('d M Y'),
                TextEntry::make('pengguna.nama')->label('Pengguna'),
                TextEntry::make('tipe')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => self::TIPE[$state]),
                TextEntry::make('nominal')->money('IDR', locale: 'id', decimalPlaces: 0),
                TextEntry::make('kategori.nama')->label('Kategori')->placeholder('-'),
                IconEntry::make('selesai')->boolean(),
                TextEntry::make('created_at')->label('Dibuat')->dateTime('d M Y H:i'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->striped()
            ->defaultSort('tanggal', 'desc')
            ->emptyStateHeading('Belum ada kegiatan dari aplikasi')
            ->columns([
                TextColumn::make('tanggal')
                    ->date('d M Y')
                    ->sortable(),
                TextColumn::make('judul')
                    ->searchable(),
                TextColumn::make('pengguna.nama')
                    ->label('Pengguna')
                    ->searchable(),
                TextColumn::make('tipe')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => self::TIPE[$state])
                    ->color(fn (string $state): string => match ($state) {
                        'pemasukan' => 'success',
                        'pengeluaran' => 'danger',
                        default => 'gray',
                    }),
                TextColumn::make('nominal')
                    ->money('IDR', locale: 'id', decimalPlaces: 0)
                    ->sortable(),
                TextColumn::make('kategori.nama')
                    ->label('Kategori')
                    ->placeholder('-'),
                IconColumn::make('selesai')
                    ->boolean(),
            ])
            ->filters([
                // 1. Pilihan tetap: tanpa uang / pemasukan / pengeluaran
                SelectFilter::make('tipe')
                    ->options(self::TIPE),

                // 2. Pilihan dari tabel kategori (otomatis ikut kalau admin nambah kategori)
                SelectFilter::make('kategori')
                    ->relationship('kategori', 'nama')
                    ->preload(),

                // 3. Pilihan pengguna, bisa diketik buat nyari
                SelectFilter::make('pengguna')
                    ->label('Pengguna')
                    ->relationship('pengguna', 'nama')
                    ->searchable()
                    ->preload(),

                // 4. Rentang tanggal: dua kolom tanggal, boleh diisi salah satu
                Filter::make('rentang_tanggal')
                    ->schema([
                        DatePicker::make('dari')->label('Dari tanggal'),
                        DatePicker::make('sampai')->label('Sampai tanggal'),
                    ])
                    ->query(fn (Builder $query, array $data): Builder => $query
                        ->when($data['dari'], fn (Builder $q, $tgl) => $q->whereDate('tanggal', '>=', $tgl))
                        ->when($data['sampai'], fn (Builder $q, $tgl) => $q->whereDate('tanggal', '<=', $tgl)))
                    ->indicateUsing(function (array $data): ?string {
                        if (! $data['dari'] && ! $data['sampai']) {
                            return null;
                        }

                        return 'Tanggal: '.($data['dari'] ?? '…').' s/d '.($data['sampai'] ?? '…');
                    }),
            ])
            ->recordActions([
                ViewAction::make(),
                DeleteAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ManageKegiatans::route('/'),
        ];
    }
}
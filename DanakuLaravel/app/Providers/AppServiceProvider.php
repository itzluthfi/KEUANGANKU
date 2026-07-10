<?php

namespace App\Providers;

use Illuminate\Pagination\Paginator;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Pagination custom bertema Danaku (halaman admin tidak memakai Tailwind,
        // sehingga view default merender ikon SVG tanpa ukuran)
        Paginator::defaultView('pagination::danaku');
    }
}

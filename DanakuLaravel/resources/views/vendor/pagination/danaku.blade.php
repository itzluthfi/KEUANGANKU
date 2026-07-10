@if ($paginator->hasPages())
    <nav class="danaku-pagination-wrap" role="navigation" aria-label="Navigasi Halaman">
        <style>
            .danaku-pagination {
                display: flex;
                list-style: none;
                gap: 8px;
                justify-content: center;
                align-items: center;
                margin: 20px 0 6px;
                padding: 0;
                flex-wrap: wrap;
            }
            .danaku-pagination li a,
            .danaku-pagination li span {
                display: inline-block;
                min-width: 34px;
                text-align: center;
                padding: 8px 12px;
                border-radius: 8px;
                background: white;
                color: #FF528F;
                text-decoration: none;
                font-weight: 600;
                font-size: 12px;
                border: 1px solid rgba(255, 82, 143, 0.15);
                transition: background 0.2s ease;
            }
            .danaku-pagination li a:hover { background: #FFF0F5; }
            .danaku-pagination li.active span {
                background: #FF528F;
                color: white;
                border-color: #FF528F;
            }
            .danaku-pagination li.disabled span {
                color: #CCC;
                border-color: #EEE;
                cursor: default;
            }
            .danaku-pagination-info {
                text-align: center;
                font-size: 11px;
                color: #999;
                font-weight: 600;
                margin-bottom: 10px;
            }
        </style>
        <ul class="danaku-pagination">
            {{-- Tombol Sebelumnya --}}
            @if ($paginator->onFirstPage())
                <li class="disabled"><span>&laquo;</span></li>
            @else
                <li><a href="{{ $paginator->previousPageUrl() }}" rel="prev">&laquo;</a></li>
            @endif

            {{-- Nomor Halaman --}}
            @foreach ($elements as $element)
                {{-- Separator "..." --}}
                @if (is_string($element))
                    <li class="disabled"><span>{{ $element }}</span></li>
                @endif

                @if (is_array($element))
                    @foreach ($element as $page => $url)
                        @if ($page == $paginator->currentPage())
                            <li class="active"><span>{{ $page }}</span></li>
                        @else
                            <li><a href="{{ $url }}">{{ $page }}</a></li>
                        @endif
                    @endforeach
                @endif
            @endforeach

            {{-- Tombol Berikutnya --}}
            @if ($paginator->hasMorePages())
                <li><a href="{{ $paginator->nextPageUrl() }}" rel="next">&raquo;</a></li>
            @else
                <li class="disabled"><span>&raquo;</span></li>
            @endif
        </ul>
        <div class="danaku-pagination-info">
            Menampilkan {{ $paginator->firstItem() }}&ndash;{{ $paginator->lastItem() }} dari {{ $paginator->total() }} data
        </div>
    </nav>
@endif

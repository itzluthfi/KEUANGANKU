@extends('admin.layout')

@section('title', 'Kelola Pengguna')
@section('header_title', 'Kelola Pengguna')
@section('header_subtitle', 'Manajemen akun terdaftar dan hapus berkas cadangan pengguna.')

@section('content')
<style>
    /* Table Styling */
    table {
        width: 100%;
        border-collapse: collapse;
    }
    th, td {
        text-align: left;
        padding: 14px;
        font-size: 13px;
    }
    th {
        background-color: #FAFAFA;
        color: #666;
        font-weight: 600;
        border-bottom: 2px solid #EEE;
    }
    td {
        border-bottom: 1px solid #F5F5F5;
        color: #444;
    }
    tr:hover td {
        background-color: #FAFAFA;
    }
    
    .btn-delete {
        background: #FFEBEE;
        color: #D32F2F;
        border: 1px solid #FFCDD2;
        padding: 8px 14px;
        border-radius: 10px;
        font-size: 11px;
        font-weight: 800;
        cursor: pointer;
        transition: all 0.3s ease;
        display: flex;
        align-items: center;
        gap: 6px;
    }
    .btn-delete:hover {
        background: #D32F2F;
        color: white;
        box-shadow: 0 4px 15px rgba(211, 47, 47, 0.2);
    }
    
    .pagination {
        display: flex;
        list-style: none;
        gap: 8px;
        justify-content: center;
        margin-top: 20px;
    }
    .pagination li a, .pagination li span {
        padding: 8px 14px;
        border-radius: 8px;
        background: white;
        color: #FF528F;
        text-decoration: none;
        font-weight: 600;
        font-size: 12px;
        border: 1px solid rgba(255, 82, 143, 0.1);
    }
    .pagination li.active span {
        background: #FF528F;
        color: white;
    }
</style>

<div class="card-panel">
    <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 15px; margin-bottom: 25px; border-bottom: 1px solid #F5F5F5; padding-bottom: 15px;">
        <div class="card-panel-title" style="margin-bottom: 0;"><i class="fa-solid fa-users" style="color:#FF528F;"></i> Daftar Pengguna Danaku App</div>
        <form action="{{ route('admin.users') }}" method="GET" style="display: flex; gap: 10px; align-items: center;">
            <div style="position: relative; display: flex; align-items: center;">
                <i class="fa-solid fa-magnifying-glass" style="position: absolute; left: 12px; color: #AAA; font-size: 13px;"></i>
                <input type="text" name="search" value="{{ $search ?? '' }}" placeholder="Cari nama atau email..." style="padding: 10px 12px 10px 35px; border-radius: 12px; border: 1px solid #DDD; font-size: 13px; width: 220px; outline: none; transition: border-color 0.3s;" onfocus="this.style.borderColor='#FF528F'" onblur="this.style.borderColor='#DDD'">
            </div>
            <button type="submit" style="background: #FF528F; color: white; border: none; padding: 10px 16px; border-radius: 12px; font-weight: bold; font-size: 13px; cursor: pointer; transition: all 0.3s;" onmouseover="this.style.background='#FF7A9F'" onmouseout="this.style.background='#FF528F'">Cari</button>
            @if(!empty($search))
                <a href="{{ route('admin.users') }}" style="background: #F0F0F0; color: #555; text-decoration: none; padding: 10px 16px; border-radius: 12px; font-weight: bold; font-size: 13px; display: inline-flex; align-items: center; border: 1px solid #DDD;">Reset</a>
            @endif
        </form>
    </div>
    @if(empty($usersList))
        <div style="text-align:center; padding: 40px; color:#999; font-size:14px;">
            @if(!empty($search))
                Tidak ada pengguna yang cocok dengan pencarian "{{ $search }}".
            @else
                Belum ada pengguna terdaftar di server.
            @endif
        </div>
    @else
        <table>
            <thead>
                <tr>
                    <th>Nama</th>
                    <th>Email</th>
                    <th>Tanggal Terdaftar</th>
                    <th>Jumlah Transaksi</th>
                    <th>Ukuran Backup</th>
                    <th>Token AI</th>
                    <th>Sinkronisasi Terakhir</th>
                    <th style="text-align: right;">Aksi</th>
                </tr>
            </thead>
            <tbody>
                @foreach($usersList as $user)
                    <tr>
                        <td><strong>{{ $user['name'] }}</strong></td>
                        <td>{{ $user['email'] }}</td>
                        <td>{{ $user['created_at'] }}</td>
                        <td><span style="font-weight:bold; color:#FF528F;">{{ $user['transactions'] }}</span> transaksi</td>
                        <td>{{ $user['backup_size'] }}</td>
                        <td><strong>{{ number_format($user['tokens']) }}</strong> tok</td>
                        <td>{{ $user['last_sync'] }}</td>
                        <td style="text-align: right; display: flex; gap: 8px; justify-content: flex-end;">
                            <a href="{{ route('admin.users.transactions', $user['id']) }}" style="background:#E3F2FD; color:#1976D2; border:1px solid #BBDEFB; padding: 8px 14px; border-radius: 10px; font-size:11px; font-weight:800; text-decoration:none; display:inline-flex; align-items:center; gap:6px;">
                                <i class="fa-solid fa-receipt"></i> Detail Transaksi
                            </a>
                            <form id="deleteForm-{{ $user['id'] }}" action="{{ route('admin.users.delete', $user['id']) }}" method="POST" style="display:none;">
                                @csrf
                                @method('DELETE')
                            </form>
                            <button type="button" class="btn-delete" style="display:inline-flex;" onclick="confirmDeleteUser({{ $user['id'] }}, '{{ $user['name'] }}')">
                                <i class="fa-solid fa-trash-can"></i> Hapus Akun
                            </button>
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
        
        <!-- Pagination Links -->
        <div style="display:flex; justify-content:center;">
            {{ $users->links() }}
        </div>
    @endif
</div>
@endsection

@section('scripts')
<script>
    function confirmDeleteUser(userId, userName) {
        Swal.fire({
            title: 'Hapus Pengguna?',
            text: "Anda yakin ingin menghapus akun '" + userName + "'? Semua database cadangan awan miliknya akan dihapus secara permanen dari server!",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#D32F2F',
            cancelButtonColor: '#aaa',
            confirmButtonText: 'Ya, Hapus Permanen',
            cancelButtonText: 'Batal',
            reverseButtons: true
        }).then((result) => {
            if (result.isConfirmed) {
                document.getElementById('deleteForm-' + userId).submit();
            }
        })
    }
</script>
@endsection

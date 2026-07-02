<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Admin Console') - Danaku</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Outfit', sans-serif;
        }
        body {
            background-color: #F4F7F6;
            color: #333;
            display: flex;
            min-height: 100vh;
        }
        
        /* Sidebar */
        .sidebar {
            width: 280px;
            background: linear-gradient(180deg, #FF528F 0%, #FF7A9F 100%);
            color: white;
            padding: 30px 20px;
            display: flex;
            flex-direction: column;
            box-shadow: 4px 0 15px rgba(255, 82, 143, 0.1);
            position: fixed;
            height: 100vh;
            overflow-y: auto;
        }
        .sidebar-brand {
            font-size: 24px;
            font-weight: 800;
            margin-bottom: 35px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .sidebar-brand i {
            font-size: 28px;
        }
        
        .sidebar-section-title {
            font-size: 11px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin: 20px 0 8px 10px;
            color: rgba(255, 255, 255, 0.6);
        }
        
        .sidebar-menu {
            list-style: none;
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .sidebar-menu li a {
            display: flex;
            align-items: center;
            gap: 15px;
            color: rgba(255, 255, 255, 0.85);
            text-decoration: none;
            padding: 12px 16px;
            border-radius: 15px;
            font-weight: 600;
            font-size: 13px;
            transition: all 0.3s ease;
        }
        .sidebar-menu li.active a, .sidebar-menu li a:hover {
            background: white;
            color: #FF528F;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
        }
        
        /* Main Content Area */
        .main-container {
            flex: 1;
            margin-left: 280px;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        .main-content {
            flex: 1;
            padding: 40px;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
        }
        .header h1 {
            font-size: 28px;
            font-weight: 800;
            color: #333;
        }
        .btn-logout {
            background: #FFCDD2;
            color: #C62828;
            border: none;
            padding: 10px 20px;
            border-radius: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 13px;
        }
        .btn-logout:hover {
            background: #C62828;
            color: white;
        }
        
        /* Common Cards */
        .card-panel {
            background: white;
            padding: 24px;
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.02);
            border: 1px solid rgba(0, 0, 0, 0.03);
            margin-bottom: 30px;
        }
        .card-panel-title {
            font-size: 16px;
            font-weight: 700;
            margin-bottom: 20px;
            color: #333;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        /* Helper Badges */
        .badge {
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 10px;
            font-weight: 800;
            text-transform: uppercase;
        }
        .badge-success { background: #E8F5E9; color: #2E7D32; }
        .badge-danger { background: #FFEBEE; color: #C62828; }
        
        /* SweetAlert Styling Customisation */
        .swal2-popup {
            font-family: 'Outfit', sans-serif !important;
            border-radius: 24px !important;
        }
    </style>
    @yield('styles')
</head>
<body>
    <!-- Sidebar -->
    <div class="sidebar">
        <div class="sidebar-brand">
            <i class="fa-solid fa-piggy-bank"></i>
            <span>Danaku Console</span>
        </div>
        
        <div class="sidebar-section-title">Monitoring & Ringkasan</div>
        <ul class="sidebar-menu">
            <li class="{{ Route::is('admin.dashboard') ? 'active' : '' }}">
                <a href="{{ route('admin.dashboard') }}"><i class="fa-solid fa-chart-pie"></i> Finansial Global</a>
            </li>
        </ul>
        
        <div class="sidebar-section-title">Konsol Intelligence</div>
        <ul class="sidebar-menu">
            <li class="{{ Route::is('admin.ai-monitoring') ? 'active' : '' }}">
                <a href="{{ route('admin.ai-monitoring') }}"><i class="fa-solid fa-microchip"></i> Monitoring Token AI</a>
            </li>
        </ul>
        
        <div class="sidebar-section-title">Cadangan & Data User</div>
        <ul class="sidebar-menu">
            <li class="{{ Route::is('admin.users') ? 'active' : '' }}">
                <a href="{{ route('admin.users') }}"><i class="fa-solid fa-users-gear"></i> Kelola Pengguna</a>
            </li>
        </ul>
    </div>

    <!-- Main Container -->
    <div class="main-container">
        <div class="main-content">
            <div class="header">
                <div>
                    <h1>@yield('header_title')</h1>
                    <p style="font-size:13px; color:#888;">@yield('header_subtitle')</p>
                </div>
                <form id="logoutForm" action="{{ route('logout') }}" method="POST" style="display:none;">
                    @csrf
                </form>
                <button type="button" class="btn-logout" onclick="confirmLogout()"><i class="fa-solid fa-right-from-bracket"></i> Keluar</button>
            </div>
            
            @yield('content')
        </div>
    </div>

    <script>
        function confirmLogout() {
            Swal.fire({
                title: 'Konfirmasi Keluar',
                text: "Apakah Anda yakin ingin keluar dari panel administrator?",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#FF528F',
                cancelButtonColor: '#aaa',
                confirmButtonText: 'Ya, Keluar',
                cancelButtonText: 'Batal',
                reverseButtons: true
            }).then((result) => {
                if (result.isConfirmed) {
                    document.getElementById('logoutForm').submit();
                }
            })
        }

        // Tampilkan SweetAlert Notifikasi jika ada Session Success/Error
        @if (session('success'))
            Swal.fire({
                title: 'Sukses!',
                text: "{{ session('success') }}",
                icon: 'success',
                confirmButtonColor: '#FF528F'
            });
        @endif

        @if (session('error'))
            Swal.fire({
                title: 'Gagal!',
                text: "{{ session('error') }}",
                icon: 'error',
                confirmButtonColor: '#FF528F'
            });
        @endif
    </script>
    @yield('scripts')
</body>
</html>

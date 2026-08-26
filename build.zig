const std = @import("std");
const AutoConfigHeaderStep = @import("autoconfigheader").AutoConfigHeaderStep;

const Assertions = enum {
    auto,
    disabled,
    release,
    enabled,
    paranoid,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cpu_x86 = target.result.cpu.arch == .x86;
    const cpu_x64 = target.result.cpu.arch == .x86_64;
    const cpu_powerpc32 = target.result.cpu.arch == .powerpc or target.result.cpu.arch == .powerpcle;
    const cpu_powerpc64 = target.result.cpu.arch == .powerpc64 or target.result.cpu.arch == .powerpc64le;
    const cpu_arm32 = target.result.cpu.arch == .arm or target.result.cpu.arch == .armeb;
    const cpu_arm64 = target.result.cpu.arch == .aarch64 or target.result.cpu.arch == .aarch64_be;
    const cpu_loongarch64 = target.result.cpu.arch == .loongarch64;

    const windows = target.result.os.tag == .windows;
    const macos = target.result.os.tag == .macos;
    const linux = target.result.os.tag == .linux;
    const ios = target.result.os.tag == .ios;
    const tvos = target.result.os.tag == .tvos;
    const visionos = target.result.os.tag == .visionos;
    const watchos = target.result.os.tag == .watchos;
    const apple = macos or ios or tvos or visionos or watchos;
    const bsdlike = target.result.os.tag == .freebsd or target.result.os.tag == .openbsd or target.result.os.tag == .netbsd;
    const emscripten = target.result.os.tag == .emscripten;
    const psp = target.result.os.tag == .psp;
    const ps2 = false;
    const n3ds = target.result.os.tag == .@"3ds";
    const vita = target.result.os.tag == .vita;

    const android = target.result.abi.isAndroid();
    // const musl = target.result.abi.isMusl();

    const legalize_step = b.step("legalize", "check compile time options for misconfigurations");

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Linkage type for the library") orelse .static;
    const audio = b.option(bool, "SDL_AUDIO", "Enable SDL audio support") orelse true;
    const video = b.option(bool, "SDL_VIDEO", "Enable SDL video support") orelse true;
    const gpu = b.option(bool, "SDL_GPU", "Enable SDL GPU support") orelse video;
    if (gpu and !video) {
        const fail = b.addFail("SDL_GPU requires SDL_VIDEO to be enabled");
        legalize_step.dependOn(&fail.step);
    }
    const render = b.option(bool, "SDL_RENDER", "Enable SDL renderer support") orelse video;
    if (render and !video) {
        const fail = b.addFail("SDL_RENDER requires SDL_VIDEO to be enabled");
        legalize_step.dependOn(&fail.step);
    }
    const camera = b.option(bool, "SDL_CAMERA", "Enable SDL camera support") orelse video;
    if (camera and !video) {
        const fail = b.addFail("SDL_CAMERA requires SDL_VIDEO to be enabled");
        legalize_step.dependOn(&fail.step);
    }
    const joystick = b.option(bool, "SDL_JOYSTICK", "Enable SDL joystick support") orelse true;
    const haptic = b.option(bool, "SDL_HAPTIC", "Enable SDL haptic support") orelse joystick;
    if (haptic and !joystick) {
        const fail = b.addFail("SDL_HAPTIC requires SDL_JOYSTICK to be enabled");
        legalize_step.dependOn(&fail.step);
    }
    const hidapi = b.option(bool, "SDL_HIDAPI", "Enable SDL HIDAPI support") orelse !visionos;
    const power = b.option(bool, "SDL_POWER", "Enable SDL power support") orelse true;
    const sensor = b.option(bool, "SDL_SENSOR", "Enable SDL sensor support") orelse true;
    const dialog = b.option(bool, "SDL_DIALOG", "Enable SDL dialog support") orelse true;

    const assertions = b.option(Assertions, "SDL_ASSERTIONS", "Enable internal sanity checks") orelse .auto;
    const assembly = b.option(bool, "SDL_ASSEMBLY", "Enable assembly routines") orelse true;
    const avx = b.option(bool, "SDL_AVX", "Use AVX assembly routines") orelse assembly and (cpu_x86 or cpu_x64);
    if (avx and !(assembly and (cpu_x86 or cpu_x64))) {
        const fail = b.addFail("SDL_AVX requires SDL_ASSEMBLY to be enabled and target CPU to be x86 or x86_64");
        legalize_step.dependOn(&fail.step);
    }
    const avx2 = b.option(bool, "SDL_AVX2", "Use AVX2 assembly routines") orelse assembly and (cpu_x86 or cpu_x64);
    if (avx2 and !(assembly and (cpu_x86 or cpu_x64))) {
        const fail = b.addFail("SDL_AVX2 requires SDL_ASSEMBLY to be enabled and target CPU to be x86 or x86_64");
        legalize_step.dependOn(&fail.step);
    }
    const avx512f = b.option(bool, "SDL_AVX512F", "Use AVX-512 assembly routines") orelse assembly and (cpu_x86 or cpu_x64);
    if (avx512f and !(assembly and (cpu_x86 or cpu_x64))) {
        const fail = b.addFail("SDL_AVX512F requires SDL_ASSEMBLY to be enabled and target CPU to be x86 or x86_64");
        legalize_step.dependOn(&fail.step);
    }
    const sse = b.option(bool, "SDL_SSE", "Use SSE assembly routines") orelse assembly and (cpu_x86 or cpu_x64);
    if (sse and !(assembly and (cpu_x86 or cpu_x64))) {
        const fail = b.addFail("SDL_SSE requires SDL_ASSEMBLY to be enabled and target CPU to be x86 or x86_64");
        legalize_step.dependOn(&fail.step);
    }
    const sse2 = b.option(bool, "SDL_SSE2", "Use SSE2 assembly routines") orelse assembly and (cpu_x86 or cpu_x64);
    if (sse2 and !(assembly and (cpu_x86 or cpu_x64))) {
        const fail = b.addFail("SDL_SSE2 requires SDL_ASSEMBLY to be enabled and target CPU to be x86 or x86_64");
        legalize_step.dependOn(&fail.step);
    }
    const sse3 = b.option(bool, "SDL_SSE3", "Use SSE3 assembly routines") orelse assembly and (cpu_x86 or cpu_x64);
    if (sse3 and !(assembly and (cpu_x86 or cpu_x64))) {
        const fail = b.addFail("SDL_SSE3 requires SDL_ASSEMBLY to be enabled and target CPU to be x86 or x86_64");
        legalize_step.dependOn(&fail.step);
    }
    const sse4_1 = b.option(bool, "SDL_SSE4_1", "Use SSE4.1 assembly routines") orelse assembly and (cpu_x86 or cpu_x64);
    if (sse4_1 and !(assembly and (cpu_x86 or cpu_x64))) {
        const fail = b.addFail("SDL_SSE4_1 requires SDL_ASSEMBLY to be enabled and target CPU to be x86 or x86_64");
        legalize_step.dependOn(&fail.step);
    }
    const sse4_2 = b.option(bool, "SDL_SSE4_2", "Use SSE4.2 assembly routines") orelse assembly and (cpu_x86 or cpu_x64);
    if (sse4_2 and !(assembly and (cpu_x86 or cpu_x64))) {
        const fail = b.addFail("SDL_SSE4_2 requires SDL_ASSEMBLY to be enabled and target CPU to be x86 or x86_64");
        legalize_step.dependOn(&fail.step);
    }
    const mmx = b.option(bool, "SDL_MMX", "Use MMX assembly routines") orelse assembly and (cpu_x86 or cpu_x64);
    if (mmx and !(assembly and (cpu_x86 or cpu_x64))) {
        const fail = b.addFail("SDL_MMX requires SDL_ASSEMBLY to be enabled and target CPU to be x86 or x86_64");
        legalize_step.dependOn(&fail.step);
    }
    const altivec = b.option(bool, "SDL_ALTIVEC", "Use Altivec assembly routines") orelse assembly and (cpu_powerpc32 or cpu_powerpc64);
    if (altivec and !(assembly and (cpu_powerpc32 or cpu_powerpc64))) {
        const fail = b.addFail("SDL_ALTIVEC requires SDL_ASSEMBLY to be enabled and target CPU to be PowerPC or PowerPC64");
        legalize_step.dependOn(&fail.step);
    }
    const neon = b.option(bool, "SDL_NEON", "Use NEON assembly routines") orelse assembly and (cpu_arm32 or cpu_arm64);
    if (neon and !(assembly and (cpu_arm32 or cpu_arm64))) {
        const fail = b.addFail("SDL_NEON requires SDL_ASSEMBLY to be enabled and target CPU to be ARM or ARM64");
        legalize_step.dependOn(&fail.step);
    }
    const lsx = b.option(bool, "SDL_LSX", "Use LSX assembly routines") orelse assembly and cpu_loongarch64;
    if (lsx and !assembly and cpu_loongarch64) {
        const fail = b.addFail("SDL_LSX requires SDL_ASSEMBLY to be enabled and target CPU to be LoongArch64");
        legalize_step.dependOn(&fail.step);
    }
    const lasx = b.option(bool, "SDL_LASX", "Use LASX assembly routines") orelse assembly and cpu_loongarch64;
    if (lasx and !assembly and cpu_loongarch64) {
        const fail = b.addFail("SDL_LASX requires SDL_ASSEMBLY to be enabled and target CPU to be LoongArch64");
        legalize_step.dependOn(&fail.step);
    }
    const libc = b.option(bool, "SDL_LIBC", "Use the system C library") orelse true;
    // const system_iconv = b.option(bool, "SDL_SYSTEM_ICONV", "Use iconv() from system-installed libraries") orelse !windows and !apple and !ios and !tvos and !visionos and !watchos;
    const libiconv = b.option(bool, "SDL_LIBICONV", "Prefer iconv() from libiconv, if available, over libc version") orelse false;
    const gcc_atomics = b.option(bool, "SDL_GCC_ATOMICS", "Use gcc builtin atomics") orelse true;
    const dbus = b.option(bool, "SDL_DBUS", "Enable D-Bus support") orelse linux;
    // const liburing = b.option(bool, "SDL_LIBURING", "Enable liburing support") orelse linux;
    const liburing = false;
    const diskaudio = b.option(bool, "SDL_DISKAUDIO", "Support the disk writer audio driver") orelse audio;
    const dummyaudio = b.option(bool, "SDL_DUMMYAUDIO", "Support the dummy audio driver") orelse audio;
    const dummyvideo = b.option(bool, "SDL_DUMMYVIDEO", "Use dummy video driver") orelse video;
    // const ibus = b.option(bool, "SDL_IBUS", "Enable IBus support") orelse linux;
    const ibus = false;
    const opengl = b.option(bool, "SDL_OPENGL", "Include OpenGL support") orelse video and !apple;
    const opengles = b.option(bool, "SDL_OPENGLES", "Include OpenGL ES support") orelse video and !apple and !apple;
    const pthreads = b.option(bool, "SDL_PTHREADS", "Use POSIX threads for multi-threading") orelse linux or apple;
    // const pthreads_sem = b.option(bool, "SDL_PTHREADS_SEM", "Use pthread semaphores") orelse pthreads;
    const oss = b.option(bool, "SDL_OSS", "Support the OSS audio API") orelse audio and false;
    // const alsa = b.option(bool, "SDL_ALSA", "Support the ALSA audio API") orelse audio and linux;
    const alsa = false;
    // const alsa_shared = b.option(bool, "SDL_ALSA_SHARED", "Dynamically load ALSA audio support") orelse alsa and false;
    const jack = b.option(bool, "SDL_JACK", "Support the JACK audio API") orelse false;
    // const jack_shared = b.option(bool, "SDL_JACK_SHARED", "Dynamically load JACK audio support") orelse jack and false;
    // const pipewire = b.option(bool, "SDL_PIPEWIRE", "Use Pipewire audio") orelse audio and false;
    const pipewire = false;
    // const pipewire_shared = b.option(bool, "SDL_PIPEWIRE_SHARED", "Dynamically load Pipewire support") orelse pipewire and false;
    // const pulseaudio = b.option(bool, "SDL_PULSEAUDIO", "Use PulseAudio") orelse audio and linux;
    const pulseaudio = false;
    // const pulseaudio_shared = b.option(bool, "SDL_PULSEAUDIO_SHARED", "Dynamically load PulseAudio support") orelse pulseaudio and false;
    // const sndio = b.option(bool, "SDL_SNDIO", "Support the sndio audio API") orelse audio and linux;
    const sndio = false;
    // const sndio_shared = b.option(bool, "SDL_SNDIO_SHARED", "Dynamically load the sndio audio API") orelse sndio and false;
    // const rpath = b.option(bool, "SDL_RPATH", "Use an rpath when linking SDL");
    // const clock_gettime = b.option(bool, "SDL_CLOCK_GETTIME", "Use clock_gettime() instead of gettimeofday()") orelse unix or android;
    const x11 = b.option(bool, "SDL_X11", "Use X11 video driver") orelse linux and video;
    // const x11_shared = b.option(bool, "SDL_X11_SHARED", "Dynamically load X11 support") orelse x11 and false;
    const x11_xcursor = b.option(bool, "SDL_X11_XCURSOR", "Enable Xcursor support") orelse x11 and false;
    const x11_xdbe = b.option(bool, "SDL_X11_XDBE", "Enable Xdbe support") orelse x11 and false;
    const x11_xinput = b.option(bool, "SDL_X11_XINPUT", "Enable XInput support") orelse x11 and false;
    const x11_xfixes = b.option(bool, "SDL_X11_XFIXES", "Enable Xfixes support") orelse x11 and false;
    const x11_xrandr = b.option(bool, "SDL_X11_XRANDR", "Enable Xrandr support") orelse x11 and false;
    const x11_xscrnsaver = b.option(bool, "SDL_X11_XSCRNSAVER", "Enable Xscrnsaver support") orelse x11 and false;
    const x11_xshape = b.option(bool, "SDL_X11_XSHAPE", "Enable XShape support") orelse x11 and false;
    const x11_xsync = b.option(bool, "SDL_X11_XSYNC", "Enable Xsync support") orelse x11 and false;
    // const wayland = b.option(bool, "SDL_WAYLAND", "Use Wayland video driver") orelse linux and video and !x11;
    const wayland = false;
    // const wayland_shared = b.option(bool, "SDL_WAYLAND_SHARED", "Dynamically load Wayland support") orelse wayland and false;
    const wayland_libdecor = b.option(bool, "SDL_WAYLAND_LIBDECOR", "Use client-side window decorations on Wayland") orelse wayland;
    // const wayland_libdecor_shared = b.option(bool, "SDL_WAYLAND_LIBDECOR_SHARED", "Dynamically load libdecor support") orelse wayland_libdecor and false;
    // const rpi = b.option(bool, "SDL_RPI", "Use Raspberry Pi video driver") orelse false;
    // const rockchip = b.option(bool, "SDL_ROCKCHIP", "Use ROCKCHIP Hardware Acceleration video driver") orelse false;
    const cocoa = b.option(bool, "SDL_COCOA", "Use Cocoa video driver") orelse apple and video;
    const directx = b.option(bool, "SDL_DIRECTX", "Use DirectX for Windows audio/video") orelse windows and (video or audio);
    const xinput = b.option(bool, "SDL_XINPUT", "Use Xinput for Windows") orelse windows;
    const wasapi = b.option(bool, "SDL_WASAPI", "Use the Windows WASAPI audio driver") orelse windows and audio;
    const render_d3d = b.option(bool, "SDL_RENDER_D3D", "Enable the Direct3D 9 render driver") orelse render and directx;
    const render_d3d11 = b.option(bool, "SDL_RENDER_D3D11", "Enable the Direct3D 11 render driver") orelse render and directx;
    const render_d3d12 = b.option(bool, "SDL_RENDER_D3D12", "Enable the Direct3D 12 render driver") orelse render and directx;
    const render_metal = b.option(bool, "SDL_RENDER_METAL", "Enable the Metal render driver") orelse render and apple;
    const render_gpu = b.option(bool, "SDL_RENDER_GPU", "Enable the SDL_GPU render driver") orelse render and gpu;
    // const vivante = b.option(bool, "SDL_VIVANTE", "Use Vivante EGL video driver") orelse video and unix and cpu_arm32;
    const vulkan = b.option(bool, "SDL_VULKAN", "Enable Vulkan support") orelse video and (android or linux or bsdlike or windows);
    const render_vulkan = b.option(bool, "SDL_RENDER_VULKAN", "Enable the Vulkan render driver") orelse render and vulkan;
    const metal = b.option(bool, "SDL_METAL", "Enable Metal support") orelse video and apple;
    // const openvr = b.option(bool, "SDL_OPENVR", "Use OpenVR video driver") orelse false;
    const kmsdrm = b.option(bool, "SDL_KMSDRM", "Use KMS DRM video driver") orelse linux and false;
    // const kmsdrm_shared = b.option(bool, "SDL_KMSDRM_SHARED", "Dynamically load KMS DRM support") orelse kmsdrm and false;
    const offscreen = b.option(bool, "SDL_OFFSCREEN", "Use offscreen video driver") orelse true;
    const dummycamera = b.option(bool, "SDL_DUMMYCAMERA", "Support the dummy camera driver") orelse camera;
    // const backgrounding_signal = b.option(bool, "SDL_BACKGROUNDING_SIGNAL", "number to use for magic backgrounding signal or 'OFF'") orelse false;
    // const foregrounding_signal = b.option(bool, "SDL_FOREGROUNDING_SIGNAL", "number to use for magic foregrounding signal or 'OFF'") orelse false;
    // const hidapi_libusb = b.option(bool, "SDL_HIDAPI_LIBUSB", "Use libusb for low level joystick drivers") orelse hidapi and linux;
    const hidapi_libusb = false;
    // const hidapi_libusb_shared = b.option(bool, "SDL_HIDAPI_LIBUSB_SHARED", "Dynamically load libusb support") orelse hidapi_libusb and false;
    const hidapi_joystick = b.option(bool, "SDL_HIDAPI_JOYSTICK", "Use HIDAPI for low level joystick drivers") orelse hidapi and joystick;
    const virtual_joystick = b.option(bool, "SDL_VIRTUAL_JOYSTICK", "Enable the virtual-joystick driver") orelse hidapi;
    // const libudev = b.option(bool, "SDL_LIBUDEV", "Enable libudev support") orelse linux;
    const libudev = false;
    // const asan = b.option(bool, "SDL_ASAN", "Use AddressSanitizer to detect memory errors");
    // const ccache = b.option(bool, "SDL_CCACHE", "Use Ccache to speed up build");
    // const clang_tidy = b.option(bool, "SDL_CLANG_TIDY", "Run clang-tidy static analysis");
    // const gpu_dxvk = b.option(bool, "SDL_GPU_DXVK", "Build SDL_GPU with DXVK support") orelse false;

    const flags = .{
        "-DUSING_GENERATED_CONFIG_H",
        switch (linkage) {
            .static => "-DSDL_STATIC_LIB",
            .dynamic => "",
        },
    };

    const sdl_dep = b.dependency("sdl", .{});

    const config_header_h_step = AutoConfigHeaderStep.create(b, target, .{
        .style = .{ .cmake = sdl_dep.path("include/build_config/SDL_build_config.h.cmake") },
        .include_path = "SDL_build_config.h",
    });
    if (gcc_atomics) {
        config_header_h_step.addHaveFunction("HAVE_GCC_ATOMICS", "__sync_lock_test_and_set((int *)0, 0);(void)__sync_fetch_and_add((int *)0, 0);(void)__sync_bool_compare_and_swap((int *)0, 0, 0)", &.{});
        config_header_h_step.addHaveFunction("HAVE_GCC_SYNC_LOCK_TEST_AND_SET", "__sync_lock_test_and_set((int *)0, 0);(void)__sync_lock_release((int *)0)", &.{});
    }
    config_header_h_step.addHaveHeader("HAVE_ALLOCA_H", "alloca.h");
    config_header_h_step.addHaveHeader("HAVE_MALLOC_H", "malloc.h");
    config_header_h_step.addHaveFunction("_ALLOCA_IN_MALLOC_H", "&_alloca", &.{"malloc.h"});
    config_header_h_step.addHaveHeader("HAVE_FLOAT_H", "float.h");
    config_header_h_step.addHaveHeader("HAVE_STDARG_H", "stdarg.h");
    config_header_h_step.addHaveHeader("HAVE_STDDEF_H", "stddef.h");
    config_header_h_step.addHaveHeader("HAVE_STDINT_H", "stdint.h");
    if (libc) {
        config_header_h_step.config_header.addValues(.{ .HAVE_LIBC = true });
    }
    config_header_h_step.addHaveHeader("HAVE_ICONV_H", "iconv.h");
    config_header_h_step.addHaveHeader("HAVE_INTTYPES_H", "inttypes.h");
    config_header_h_step.addHaveHeader("HAVE_LIMITS_H", "limits.h");
    config_header_h_step.addHaveHeader("HAVE_MATH_H", "math.h");
    config_header_h_step.addHaveHeader("HAVE_MEMORY_H", "memory.h");
    config_header_h_step.addHaveHeader("HAVE_SIGNAL_H", "signal.h");
    config_header_h_step.addHaveHeader("HAVE_STDIO_H", "stdio.h");
    config_header_h_step.addHaveHeader("HAVE_STDLIB_H", "stdlib.h");
    config_header_h_step.addHaveHeader("HAVE_STRINGS_H", "strings.h");
    config_header_h_step.addHaveHeader("HAVE_STRING_H", "string.h");
    config_header_h_step.addHaveHeader("HAVE_SYS_TYPES_H", "sys/types.h");
    config_header_h_step.addHaveHeader("HAVE_WCHAR_H", "wchar.h");
    config_header_h_step.addHaveHeader("HAVE_PTHREAD_H", "pthread.h");
    config_header_h_step.addHaveHeader("HAVE_PTHREAD_NP_H", "pthread_np.h");
    config_header_h_step.addHaveHeader("HAVE_DDRAW_H", "ddraw.h");
    config_header_h_step.addHaveHeader("HAVE_DSOUND_H", "dsound.h");
    config_header_h_step.addHaveHeader("HAVE_DINPUT_H", "dinput.h");
    config_header_h_step.addHaveHeader("HAVE_XINPUT_H", "xinput.h");
    config_header_h_step.addHaveHeader("HAVE_WINDOWS_GAMING_INPUT_H", "windows.gaming.input.h");
    config_header_h_step.addHaveHeader("HAVE_GAMEINPUT_H", "gameinput.h");
    config_header_h_step.addHaveHeader("HAVE_DXGI_H", "dxgi.h");
    config_header_h_step.addHaveHeader("HAVE_DXGI1_6_H", "dxgi1_6.h");
    config_header_h_step.addHaveHeader("HAVE_MMDEVICEAPI_H", "mmdeviceapi.h");
    config_header_h_step.addHaveHeader("HAVE_TPCSHRD_H", "tpcshrd.h");
    config_header_h_step.addHaveHeader("HAVE_ROAPI_H", "roapi.h");
    config_header_h_step.addHaveHeader("HAVE_SHELLSCALINGAPI_H", "shellscalingapi.h");
    config_header_h_step.addHaveHeader("HAVE_SYS_INOTIFY_H", "sys/inotify.h");
    config_header_h_step.addHaveFunction("HAVE_PTHREAD_SET_NAME_NP", "&pthread_set_name_np", &.{"pthread.h"});
    config_header_h_step.addHaveFunction("HAVE_PTHREAD_SETNAME_NP", "&pthread_setname_np", &.{"pthread.h"});
    config_header_h_step.addHaveFunction("HAVE_DLOPEN_IN_LIBC", "&dlopen", &.{"dlfcn.h"});
    config_header_h_step.addHaveFunction2("HAVE_DLOPEN_IN_LIBDL", "&dlopen", &.{"dlfcn.h"}, &.{"dl"});
    config_header_h_step.addHaveFunction("HAVE_DLOPEN", "&dlopen", &.{"dlfcn.h"});
    config_header_h_step.addHaveFunction("HAVE_MALLOC", "&malloc", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_FDATASYNC", "&fdatasync", &.{"unistd.h"});
    config_header_h_step.addHaveFunction("HAVE_GETENV", "&getenv", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_SETENV", "&setenv", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_PUTENV", "&putenv", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_UNSETENV", "&unsetenv", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_GETHOSTNAME", "&gethostname", &.{"unistd.h"});
    config_header_h_step.addHaveFunction("HAVE_ABS", "&abs", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_BCOPY", "&bcopy", &.{"strings.h"});
    config_header_h_step.addHaveFunction("HAVE_MEMSET", "&memset", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_MEMCPY", "&memcpy", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_MEMMOVE", "&memmove", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_MEMCMP", "&memcmp", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_WCSLEN", "&wcslen", &.{"wchar.h"});
    config_header_h_step.addHaveFunction("HAVE_WCSNLEN", "&wcsnlen", &.{"wchar.h"});
    config_header_h_step.addHaveFunction("HAVE_WCSLCPY", "&wcslcpy", &.{"wchar.h"});
    config_header_h_step.addHaveFunction("HAVE_WCSLCAT", "&wcslcat", &.{"wchar.h"});
    config_header_h_step.addHaveFunction("HAVE_WCSSTR", "&wcsstr", &.{"wchar.h"});
    config_header_h_step.addHaveFunction("HAVE_WCSCMP", "&wcscmp", &.{"wchar.h"});
    config_header_h_step.addHaveFunction("HAVE_WCSNCMP", "&wcsncmp", &.{"wchar.h"});
    config_header_h_step.addHaveFunction("HAVE_WCSTOL", "&wcstol", &.{"wchar.h"});
    config_header_h_step.addHaveFunction("HAVE_STRLEN", "&strlen", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_STRNLEN", "&strnlen", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_STRLCPY", "&strlcpy", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_STRLCAT", "&strlcat", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_STRPBRK", "&strpbrk", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE__STRREV", "&_strrev", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_INDEX", "&index", &.{"strings.h"});
    config_header_h_step.addHaveFunction("HAVE_RINDEX", "&rindex", &.{"strings.h"});
    config_header_h_step.addHaveFunction("HAVE_STRCHR", "&strchr", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_STRRCHR", "&strrchr", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_STRSTR", "&strstr", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_STRNSTR", "&strnstr", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_STRTOK_R", "&strtok_r", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_ITOA", "&itoa", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE__LTOA", "&_ltoa", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE__UITOA", "&_uitoa", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE__ULTOA", "&_ultoa", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_STRTOL", "&strtol", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_STRTOUL", "&strtoul", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE__I64TOA", "&_i64toa", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE__UI64TOA", "&_ui64toa", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_STRTOLL", "&strtoll", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_STRTOULL", "&strtoull", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_STRTOD", "&strtod", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_ATOI", "&atoi", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_ATOF", "&atof", &.{"stdlib.h"});
    config_header_h_step.addHaveFunction("HAVE_STRCMP", "&strcmp", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_STRNCMP", "&strncmp", &.{"string.h"});
    config_header_h_step.addHaveFunction("HAVE_VSSCANF", "&vsscanf", &.{ "stdio.h", "stdarg.h" });
    config_header_h_step.addHaveFunction("HAVE_VSNPRINTF", "&vsnprintf", &.{ "stdio.h", "stdarg.h" });
    config_header_h_step.addHaveFunction("HAVE_ACOS", "&acos", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ACOSF", "&acosf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ASIN", "&asin", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ASINF", "&asinf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ATAN", "&atan", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ATANF", "&atanf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ATAN2", "&atan2", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ATAN2F", "&atan2f", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_CEIL", "&ceil", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_CEILF", "&ceilf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_COPYSIGN", "&copysign", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_COPYSIGNF", "&copysignf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE__COPYSIGN", "&_copysign", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_COS", "&cos", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_COSF", "&cosf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_EXP", "&exp", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_EXPF", "&expf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_FABS", "&fabs", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_FABSF", "&fabsf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_FLOOR", "&floor", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_FLOORF", "&floorf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_FMOD", "&fmod", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_FMODF", "&fmodf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ISINF", "isinf(0)", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ISINFF", "isinff(0)", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ISINF_FLOAT_MACRO", "isinf(0)", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ISNAN", "isnan(0)", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ISNANF", "isnanf(0)", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ISNAN_FLOAT_MACRO", "isnan(0)", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_LOG", "&log", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_LOGF", "&logf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_LOG10", "&log10", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_LOG10F", "&log10f", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_LROUND", "&lround", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_LROUNDF", "&lroundf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_MODF", "&modf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_MODFF", "&modff", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_POW", "&pow", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_POWF", "&powf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ROUND", "&round", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_ROUNDF", "&roundf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_SCALBN", "&scalbn", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_SCALBNF", "&scalbnf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_SIN", "&sin", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_SINF", "&sinf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_SQRT", "&sqrt", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_SQRTF", "&sqrtf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_TAN", "&tan", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_TANF", "&tanf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_TRUNC", "&trunc", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE_TRUNCF", "&truncf", &.{"math.h"});
    config_header_h_step.addHaveFunction("HAVE__FSEEKI64", "&_fseeki64", &.{"stdio.h"});
    config_header_h_step.addHaveFunction("HAVE_FOPEN64", "&fopen64", &.{"stdio.h"});
    config_header_h_step.addHaveFunction("HAVE_FSEEKO", "&fseeko", &.{"stdio.h"});
    config_header_h_step.addHaveFunction("HAVE_FSEEKO64", "&fseeko64", &.{"stdio.h"});
    config_header_h_step.addHaveFunction("HAVE_MEMFD_CREATE", "&memfd_create", &.{"sys/mman.h"});
    config_header_h_step.addHaveFunction("HAVE_POSIX_FALLOCATE", "&posix_fallocate", &.{});
    config_header_h_step.addHaveFunction("HAVE_SIGACTION", "&sigaction", &.{"fcntl.h"});
    config_header_h_step.addHaveFunction("HAVE_SA_SIGACTION", "&sa_sigaction", &.{"signal.h"});
    config_header_h_step.addHaveFunction("HAVE_ST_MTIM", "&st_mtim", &.{"sys/stat.h"});
    config_header_h_step.addHaveFunction("HAVE_SETJMP", "&setjmp", &.{"setjmp.h"});
    config_header_h_step.addHaveFunction("HAVE_NANOSLEEP", "&nanosleep", &.{"time.h"});
    config_header_h_step.addHaveFunction("HAVE_GMTIME_R", "&gmtime_r", &.{"time.h"});
    config_header_h_step.addHaveFunction("HAVE_LOCALTIME_R", "&localtime_r", &.{"time.h"});
    config_header_h_step.addHaveFunction("HAVE_NL_LANGINFO", "&nl_langinfo", &.{"langinfo.h"});
    config_header_h_step.addHaveFunction("HAVE_SYSCONF", "&sysconf", &.{"unistd.h"});
    config_header_h_step.addHaveFunction("HAVE_SYSCTLBYNAME", "&sysctlbyname", &.{"sys/sysctl.h"});
    config_header_h_step.addHaveFunction("HAVE_CLOCK_GETTIME", "&clock_gettime", &.{"time.h"});
    config_header_h_step.addHaveFunction("HAVE_GETPAGESIZE", "&getpagesize", &.{"unistd.h"});
    config_header_h_step.addHaveFunction("HAVE_POLL", "&poll", &.{"socket.h"});
    config_header_h_step.addHaveFunction("HAVE_INOTIFY_INIT", "&inotify_init", &.{"sys/inotify.h"});
    config_header_h_step.addHaveFunction("HAVE_INOTIFY_INIT1", "&inotify_init1", &.{"sys/inotify.h"});
    config_header_h_step.addHaveFunction("HAVE_LINUX_INPUT_H", "EVIOCGNAME(0)", &.{"linux/input.h"});
    if (dbus) {
        config_header_h_step.config_header.addValues(.{
            .HAVE_DBUS_DBUS_H = true,
            .HAVE_FCITX = true,
        });
    }
    if (ibus) {
        config_header_h_step.config_header.addValues(.{
            .HAVE_IBUS_IBUS_H = true,
            .HAVE_IBUS = true,
        });
    }
    if (ibus or dbus) {
        config_header_h_step.config_header.addValues(.{
            .SDL_USE_IME = true,
        });
    }

    config_header_h_step.config_header.addValues(.{
        .HAVE_ICONV = linux or emscripten,
        .SDL_USE_LIBICONV = libiconv,
        .HAVE_SEM_TIMEDWAIT = linux,
        .HAVE_GETAUXVAL = linux,
        .HAVE_ELF_AUX_INFO = false,
        .HAVE__EXIT = windows or linux or apple or emscripten,
        .HAVE_LIBUSB = hidapi_libusb,
        .HAVE_O_CLOEXEC = linux or macos or emscripten,
        .HAVE_LIBUDEV_H = libudev,
        .HAVE_LIBDECOR_H = wayland_libdecor,
        .HAVE_LIBURING_H = liburing,
        .USE_POSIX_SPAWN = false,
        .SDL_DEFAULT_ASSERT_LEVEL_CONFIGURED = assertions != .auto,
        .SDL_DEFAULT_ASSERT_LEVEL = switch (assertions) {
            .disabled => "0",
            .release => "1",
            .enabled => "2",
            .paranoid => "3",
            .auto => "",
        },
        .SDL_AUDIO_DISABLED = !audio,
        .SDL_VIDEO_DISABLED = !video,
        .SDL_GPU_DISABLED = !gpu,
        .SDL_RENDER_DISABLED = !render,
        .SDL_CAMERA_DISABLED = !camera,
        .SDL_JOYSTICK_DISABLED = !joystick,
        .SDL_HAPTIC_DISABLED = !haptic,
        .SDL_HIDAPI_DISABLED = !hidapi,
        .SDL_POWER_DISABLED = !power,
        .SDL_SENSOR_DISABLED = !sensor,
        .SDL_DIALOG_DISABLED = !dialog,
        .SDL_THREADS_DISABLED = emscripten,
        .SDL_AUDIO_DRIVER_ALSA = audio and alsa,
        .SDL_AUDIO_DRIVER_ALSA_DYNAMIC = "",
        .SDL_AUDIO_DRIVER_OPENSLES = audio and android,
        .SDL_AUDIO_DRIVER_AAUDIO = audio and android,
        .SDL_AUDIO_DRIVER_COREAUDIO = audio and apple,
        .SDL_AUDIO_DRIVER_DISK = audio and diskaudio,
        .SDL_AUDIO_DRIVER_DSOUND = audio and windows,
        .SDL_AUDIO_DRIVER_DUMMY = audio and dummyaudio,
        .SDL_AUDIO_DRIVER_EMSCRIPTEN = audio and emscripten,
        .SDL_AUDIO_DRIVER_HAIKU = false,
        .SDL_AUDIO_DRIVER_JACK = audio and jack,
        .SDL_AUDIO_DRIVER_JACK_DYNAMIC = "",
        .SDL_AUDIO_DRIVER_NETBSD = audio and (target.result.os.tag == .netbsd),
        .SDL_AUDIO_DRIVER_OSS = audio and oss,
        .SDL_AUDIO_DRIVER_PIPEWIRE = audio and pipewire,
        .SDL_AUDIO_DRIVER_PIPEWIRE_DYNAMIC = "",
        .SDL_AUDIO_DRIVER_PULSEAUDIO = audio and pulseaudio,
        .SDL_AUDIO_DRIVER_PULSEAUDIO_DYNAMIC = "",
        .SDL_AUDIO_DRIVER_SNDIO = audio and sndio,
        .SDL_AUDIO_DRIVER_SNDIO_DYNAMIC = "",
        .SDL_AUDIO_DRIVER_WASAPI = audio and wasapi,
        .SDL_AUDIO_DRIVER_VITA = audio and vita,
        .SDL_AUDIO_DRIVER_PSP = false,
        .SDL_AUDIO_DRIVER_PS2 = false,
        .SDL_AUDIO_DRIVER_N3DS = false,
        .SDL_AUDIO_DRIVER_QNX = false,
        .SDL_INPUT_LINUXEV = linux,
        .SDL_INPUT_LINUXKD = linux,
        .SDL_INPUT_FBSDKBIO = false,
        .SDL_INPUT_WSCONS = false,
        .SDL_HAVE_MACHINE_JOYSTICK_H = false,
        .SDL_JOYSTICK_ANDROID = joystick and false,
        .SDL_JOYSTICK_DINPUT = joystick and windows,
        .SDL_JOYSTICK_DUMMY = false,
        .SDL_JOYSTICK_EMSCRIPTEN = joystick and emscripten,
        .SDL_JOYSTICK_GAMEINPUT = false,
        .SDL_JOYSTICK_HAIKU = false,
        .SDL_JOYSTICK_HIDAPI = joystick and hidapi,
        .SDL_JOYSTICK_IOKIT = joystick and apple,
        .SDL_JOYSTICK_LINUX = joystick and linux,
        .SDL_JOYSTICK_MFI = joystick and apple,
        .SDL_JOYSTICK_N3DS = false,
        .SDL_JOYSTICK_PS2 = false,
        .SDL_JOYSTICK_PSP = false,
        .SDL_JOYSTICK_RAWINPUT = joystick and windows,
        .SDL_JOYSTICK_USBHID = false,
        .SDL_JOYSTICK_VIRTUAL = joystick and virtual_joystick,
        .SDL_JOYSTICK_VITA = joystick and vita,
        .SDL_JOYSTICK_WGI = false,
        .SDL_JOYSTICK_XINPUT = joystick and xinput,
        .SDL_HAPTIC_DUMMY = haptic and emscripten,
        .SDL_HAPTIC_LINUX = haptic and linux,
        .SDL_HAPTIC_IOKIT = haptic and apple,
        .SDL_HAPTIC_DINPUT = haptic and windows,
        .SDL_HAPTIC_ANDROID = haptic and android,
        .SDL_LIBUSB_DYNAMIC = "",
        .SDL_UDEV_DYNAMIC = "",
        .SDL_PROCESS_DUMMY = emscripten,
        .SDL_PROCESS_POSIX = linux or apple,
        .SDL_PROCESS_WINDOWS = windows,
        .SDL_SENSOR_ANDROID = sensor and android,
        .SDL_SENSOR_COREMOTION = sensor and apple,
        .SDL_SENSOR_WINDOWS = sensor and windows,
        .SDL_SENSOR_DUMMY = !sensor,
        .SDL_SENSOR_VITA = sensor and vita,
        .SDL_SENSOR_N3DS = false,
        .SDL_LOADSO_DLOPEN = linux or apple or emscripten,
        .SDL_LOADSO_DUMMY = false,
        .SDL_LOADSO_WINDOWS = windows,
        .SDL_THREAD_GENERIC_COND_SUFFIX = windows,
        .SDL_THREAD_GENERIC_RWLOCK_SUFFIX = windows,
        .SDL_THREAD_PTHREAD = !windows,
        .SDL_THREAD_PTHREAD_RECURSIVE_MUTEX = linux or apple or emscripten,
        .SDL_THREAD_PTHREAD_RECURSIVE_MUTEX_NP = false,
        .SDL_THREAD_WINDOWS = windows,
        .SDL_THREAD_VITA = vita,
        .SDL_THREAD_PSP = false,
        .SDL_THREAD_PS2 = false,
        .SDL_THREAD_N3DS = false,
        .SDL_TIME_UNIX = linux or apple or emscripten,
        .SDL_TIME_WINDOWS = windows,
        .SDL_TIME_VITA = vita,
        .SDL_TIME_PSP = psp,
        .SDL_TIME_PS2 = ps2,
        .SDL_TIME_N3DS = n3ds,
        .SDL_TIMER_HAIKU = false,
        .SDL_TIMER_UNIX = linux or apple or emscripten,
        .SDL_TIMER_WINDOWS = windows,
        .SDL_TIMER_VITA = vita,
        .SDL_TIMER_PSP = false,
        .SDL_TIMER_PS2 = false,
        .SDL_TIMER_N3DS = false,
        .SDL_VIDEO_DRIVER_ANDROID = video and android,
        .SDL_VIDEO_DRIVER_COCOA = video and cocoa,
        .SDL_VIDEO_DRIVER_DUMMY = video and dummyvideo,
        .SDL_VIDEO_DRIVER_EMSCRIPTEN = emscripten,
        .SDL_VIDEO_DRIVER_HAIKU = false,
        .SDL_VIDEO_DRIVER_KMSDRM = kmsdrm,
        .SDL_VIDEO_DRIVER_KMSDRM_DYNAMIC = "",
        .SDL_VIDEO_DRIVER_KMSDRM_DYNAMIC_GBM = "",
        .SDL_VIDEO_DRIVER_N3DS = false,
        .SDL_VIDEO_DRIVER_OFFSCREEN = video and offscreen,
        .SDL_VIDEO_DRIVER_PS2 = false,
        .SDL_VIDEO_DRIVER_PSP = false,
        .SDL_VIDEO_DRIVER_RISCOS = false,
        .SDL_VIDEO_DRIVER_ROCKCHIP = false,
        .SDL_VIDEO_DRIVER_RPI = false,
        .SDL_VIDEO_DRIVER_UIKIT = false,
        .SDL_VIDEO_DRIVER_VITA = false,
        .SDL_VIDEO_DRIVER_VIVANTE = false,
        .SDL_VIDEO_DRIVER_VIVANTE_VDK = false,
        .SDL_VIDEO_DRIVER_OPENVR = false,
        .SDL_VIDEO_DRIVER_WAYLAND = video and wayland,
        .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC = "",
        .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_CURSOR = "",
        .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_EGL = "",
        .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_LIBDECOR = "",
        .SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_XKBCOMMON = "",
        .SDL_VIDEO_DRIVER_WINDOWS = windows,
        .SDL_VIDEO_DRIVER_X11 = video and x11,
        .SDL_VIDEO_DRIVER_X11_DYNAMIC = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XCURSOR = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XEXT = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XFIXES = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XINPUT2 = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XRANDR = "",
        .SDL_VIDEO_DRIVER_X11_DYNAMIC_XSS = "",
        .SDL_VIDEO_DRIVER_X11_HAS_XKBLOOKUPKEYSYM = video and x11,
        .SDL_VIDEO_DRIVER_X11_SUPPORTS_GENERIC_EVENTS = video and x11,
        .SDL_VIDEO_DRIVER_X11_XCURSOR = video and x11 and x11_xcursor,
        .SDL_VIDEO_DRIVER_X11_XDBE = video and x11 and x11_xdbe,
        .SDL_VIDEO_DRIVER_X11_XFIXES = video and x11 and x11_xfixes,
        .SDL_VIDEO_DRIVER_X11_XINPUT2 = video and x11 and x11_xinput,
        .SDL_VIDEO_DRIVER_X11_XINPUT2_SUPPORTS_MULTITOUCH = video and x11 and x11_xinput,
        .SDL_VIDEO_DRIVER_X11_XRANDR = video and x11 and x11_xrandr,
        .SDL_VIDEO_DRIVER_X11_XSCRNSAVER = video and x11 and x11_xscrnsaver,
        .SDL_VIDEO_DRIVER_X11_XSHAPE = video and x11 and x11_xshape,
        .SDL_VIDEO_DRIVER_X11_XSYNC = video and x11 and x11_xsync,
        .SDL_VIDEO_DRIVER_QNX = false,
        .SDL_VIDEO_RENDER_D3D = render and render_d3d,
        .SDL_VIDEO_RENDER_D3D11 = render and render_d3d11,
        .SDL_VIDEO_RENDER_D3D12 = render and render_d3d12,
        .SDL_VIDEO_RENDER_GPU = render_gpu,
        .SDL_VIDEO_RENDER_METAL = render and metal and render_metal,
        .SDL_VIDEO_RENDER_VULKAN = render and vulkan,
        .SDL_VIDEO_RENDER_OGL = render and opengl,
        .SDL_VIDEO_RENDER_OGL_ES2 = render and opengles,
        .SDL_VIDEO_RENDER_PS2 = render and false,
        .SDL_VIDEO_RENDER_PSP = render and target.result.os.tag == .psp,
        .SDL_VIDEO_RENDER_VITA_GXM = render and vita,
        .SDL_VIDEO_OPENGL = render and opengl,
        .SDL_VIDEO_OPENGL_ES = render and opengles,
        .SDL_VIDEO_OPENGL_ES2 = render and opengles,
        .SDL_VIDEO_OPENGL_CGL = render and opengl and apple,
        .SDL_VIDEO_OPENGL_GLX = render and opengl and linux,
        .SDL_VIDEO_OPENGL_WGL = render and opengl and windows,
        .SDL_VIDEO_OPENGL_EGL = render and opengles,
        .SDL_VIDEO_VULKAN = video and vulkan,
        .SDL_VIDEO_METAL = video and metal,
        .SDL_GPU_D3D11 = gpu and render_d3d11,
        .SDL_GPU_D3D12 = gpu and render_d3d12,
        .SDL_GPU_VULKAN = gpu and render_vulkan,
        .SDL_GPU_METAL = gpu and metal,
        .SDL_POWER_ANDROID = power and android,
        .SDL_POWER_LINUX = power and linux,
        .SDL_POWER_WINDOWS = power and windows,
        .SDL_POWER_appleX = power and apple,
        .SDL_POWER_UIKIT = power and false,
        .SDL_POWER_HAIKU = false,
        .SDL_POWER_EMSCRIPTEN = power and emscripten,
        .SDL_POWER_HARDWIRED = false,
        .SDL_POWER_VITA = power and vita,
        .SDL_POWER_PSP = false,
        .SDL_POWER_N3DS = false,
        .SDL_FILESYSTEM_ANDROID = android,
        .SDL_FILESYSTEM_HAIKU = false,
        .SDL_FILESYSTEM_COCOA = apple,
        .SDL_FILESYSTEM_DUMMY = false,
        .SDL_FILESYSTEM_RISCOS = false,
        .SDL_FILESYSTEM_UNIX = linux,
        .SDL_FILESYSTEM_WINDOWS = windows,
        .SDL_FILESYSTEM_EMSCRIPTEN = emscripten,
        .SDL_FILESYSTEM_VITA = vita,
        .SDL_FILESYSTEM_PSP = false,
        .SDL_FILESYSTEM_PS2 = false,
        .SDL_FILESYSTEM_N3DS = false,
        .SDL_STORAGE_STEAM = windows or linux or apple,
        .SDL_FSOPS_POSIX = linux or apple or emscripten,
        .SDL_FSOPS_WINDOWS = windows,
        .SDL_FSOPS_DUMMY = false,
        .SDL_CAMERA_DRIVER_DUMMY = camera and dummycamera,
        .SDL_CAMERA_DRIVER_DISK = camera and false,
        .SDL_CAMERA_DRIVER_V4L2 = camera and linux,
        .SDL_CAMERA_DRIVER_COREMEDIA = camera and apple,
        .SDL_CAMERA_DRIVER_ANDROID = camera and android,
        .SDL_CAMERA_DRIVER_EMSCRIPTEN = camera and emscripten,
        .SDL_CAMERA_DRIVER_MEDIAFOUNDATION = camera and windows,
        .SDL_CAMERA_DRIVER_PIPEWIRE = camera and pipewire,
        .SDL_CAMERA_DRIVER_PIPEWIRE_DYNAMIC = "",
        .SDL_CAMERA_DRIVER_VITA = camera and vita,
        .SDL_DIALOG_DUMMY = !dialog,
        .SDL_ALTIVEC_BLITTERS = false,
        .DYNAPI_NEEDS_DLOPEN = linux or apple or emscripten,
        .SDL_DISABLE_WINDOWS_IME = false,
        .SDL_GDK_TEXTINPUT = false,
        .SDL_IPHONE_KEYBOARD = false,
        .SDL_IPHONE_LAUNCHSCREEN = false,
        .SDL_VIDEO_VITA_PIB = false,
        .SDL_VIDEO_VITA_PVR = false,
        .SDL_VIDEO_VITA_PVR_OGL = false,
        .SDL_LIBDECOR_VERSION_MAJOR = null,
        .SDL_LIBDECOR_VERSION_MINOR = null,
        .SDL_LIBDECOR_VERSION_PATCH = null,
        .SDL_DISABLE_SSE = !sse,
        .SDL_DISABLE_SSE2 = !sse2,
        .SDL_DISABLE_SSE3 = !sse3,
        .SDL_DISABLE_SSE4_1 = !sse4_1,
        .SDL_DISABLE_SSE4_2 = !sse4_2,
        .SDL_DISABLE_AVX = !avx,
        .SDL_DISABLE_AVX2 = !avx2,
        .SDL_DISABLE_AVX512F = !avx512f,
        .SDL_DISABLE_MMX = !mmx,
        .SDL_DISABLE_LSX = !lsx,
        .SDL_DISABLE_LASX = !lasx,
        .SDL_DISABLE_NEON = !neon,
    });

    const uclibc_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = false,
    });
    uclibc_mod.addIncludePath(sdl_dep.path("include"));
    uclibc_mod.addIncludePath(sdl_dep.path("src"));
    uclibc_mod.addConfigHeader(config_header_h_step.config_header);
    uclibc_mod.addCSourceFiles(.{
        .root = sdl_dep.path("src"),
        .files = &uclibc_sources,
        .flags = &flags,
    });
    const uclibc = b.addLibrary(.{
        .name = "uclibc",
        .root_module = uclibc_mod,
    });

    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = libc,
    });
    if (!libc) {
        mod.linkLibrary(uclibc);
    }
    if (dbus) {
        if (b.lazyDependency("dbus", .{ .target = target, .optimize = optimize, .linkage = linkage })) |dep| {
            const lib = dep.artifact("dbus-1");
            mod.linkLibrary(lib);
        }
    }
    if (x11) {
        if (b.lazyDependency("x11", .{ .target = target, .optimize = optimize, .linkage = linkage })) |dep| {
            const lib = dep.artifact("x11");
            mod.linkLibrary(lib);
        }
        if (b.lazyDependency("xext", .{ .target = target, .optimize = optimize, .linkage = linkage })) |dep| {
            const lib = dep.artifact("xext");
            mod.linkLibrary(lib);
        }
        if (b.lazyDependency("xcb", .{ .target = target, .optimize = optimize, .linkage = linkage })) |dep| {
            const lib = dep.artifact("xcb");
            mod.linkLibrary(lib);
        }
        if (b.lazyDependency("xorgproto", .{ .target = target, .optimize = optimize })) |dep| {
            const lib = dep.artifact("xorgproto");
            mod.linkLibrary(lib);
        }
    }
    mod.addIncludePath(sdl_dep.path("include"));
    mod.addIncludePath(sdl_dep.path("src"));
    mod.addConfigHeader(config_header_h_step.config_header);

    if (windows) {
        mod.linkSystemLibrary("kernel32", .{});
        mod.linkSystemLibrary("user32", .{});
        mod.linkSystemLibrary("gdi32", .{});
        mod.linkSystemLibrary("winmm", .{});
        mod.linkSystemLibrary("imm32", .{});
        mod.linkSystemLibrary("ole32", .{});
        mod.linkSystemLibrary("oleaut32", .{});
        mod.linkSystemLibrary("version", .{});
        mod.linkSystemLibrary("uuid", .{});
        mod.linkSystemLibrary("advapi32", .{});
        mod.linkSystemLibrary("setupapi", .{});
        mod.linkSystemLibrary("shell32", .{});
        mod.linkSystemLibrary("dinput8", .{});
    }

    mod.addCSourceFiles(.{
        .root = sdl_dep.path("src"),
        .files = &common_sources,
        .flags = &flags,
    });

    if (windows) {
        mod.addCSourceFiles(.{
            .root = sdl_dep.path("src"),
            .files = &windows_sources,
            .flags = &flags,
        });
    }

    if (linux) {
        mod.addCSourceFiles(.{
            .root = sdl_dep.path("src"),
            .files = &linux_sources,
            .flags = &flags,
        });
        if (dbus) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src"),
                .files = &.{
                    "core/linux/SDL_dbus.c",
                    "core/linux/SDL_system_theme.c",
                    "core/linux/SDL_fcitx.c",
                },
                .flags = &flags,
            });
        }
    }

    if (apple) {
        mod.addCSourceFiles(.{
            .root = sdl_dep.path("src"),
            .files = &apple_sources,
            .flags = &flags,
        });
    }

    if (pthreads) {
        mod.addCSourceFiles(.{
            .root = sdl_dep.path("src/thread/pthread"),
            .files = &.{
                "SDL_systhread.c",
                "SDL_sysmutex.c",
                "SDL_syscond.c",
                "SDL_sysrwlock.c",
                "SDL_systls.c",
                "SDL_syssem.c",
            },
            .flags = &flags,
        });
    } else if (windows) {
        mod.addCSourceFiles(.{
            .root = sdl_dep.path("src/thread"),
            .files = &.{
                "windows/SDL_syscond_cv.c",
                "windows/SDL_sysmutex.c",
                "windows/SDL_sysrwlock_srw.c",
                "windows/SDL_syssem.c",
                "windows/SDL_systhread.c",
                "windows/SDL_systls.c",
                "generic/SDL_syscond.c",
                "generic/SDL_sysrwlock.c",
            },
            .flags = &flags,
        });
    } else {
        mod.addCSourceFiles(.{
            .root = sdl_dep.path("src/thread/generic"),
            .files = &.{
                "SDL_syscond.c",
                "SDL_sysmutex.c",
                "SDL_sysrwlock.c",
                "SDL_syssem.c",
                "SDL_systhread.c",
                "SDL_systls.c",
            },
            .flags = &flags,
        });
    }

    if (joystick) {
        if (hidapi_joystick) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/joystick/hidapi"),
                .files = &.{
                    "SDL_hidapi_combined.c",
                    "SDL_hidapi_gamecube.c",
                    "SDL_hidapi_luna.c",
                    "SDL_hidapi_ps3.c",
                    "SDL_hidapi_ps4.c",
                    "SDL_hidapi_ps5.c",
                    "SDL_hidapi_rumble.c",
                    "SDL_hidapi_shield.c",
                    "SDL_hidapi_stadia.c",
                    "SDL_hidapi_steam.c",
                    "SDL_hidapi_steam_hori.c",
                    "SDL_hidapi_steamdeck.c",
                    "SDL_hidapi_switch.c",
                    "SDL_hidapi_wii.c",
                    "SDL_hidapi_xbox360.c",
                    "SDL_hidapi_xbox360w.c",
                    "SDL_hidapi_xboxone.c",
                    "SDL_hidapijoystick.c",
                },
                .flags = &flags,
            });
        }
        if (virtual_joystick) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/joystick/virtual"),
                .files = &.{"SDL_virtualjoystick.c"},
                .flags = &flags,
            });
        }
        if (windows) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/joystick/windows"),
                .files = &.{
                    "SDL_dinputjoystick.c",
                    "SDL_rawinputjoystick.c",
                    "SDL_windows_gaming_input.c",
                    "SDL_windowsjoystick.c",
                    "SDL_xinputjoystick.c",
                },
                .flags = &flags,
            });
        }
        if (linux) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/joystick/linux"),
                .files = &.{"SDL_sysjoystick.c"},
                .flags = &flags,
            });
        }
        if (apple) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/joystick"),
                .files = &.{
                    "apple/SDL_mfijoystick.m",
                    "darwin/SDL_iokitjoystick.c",
                },
                .flags = &flags,
            });
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/joystick/cocoa"),
                .files = &.{"SDL_joystick_cocoa.m"},
                .flags = &flags,
            });
        }
    }

    if (audio) {
        if (dummyaudio) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/audio/dummy"),
                .files = &.{"SDL_dummyaudio.c"},
                .flags = &flags,
            });
        }
        if (wasapi) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/audio/wasapi"),
                .files = &.{"SDL_wasapi.c"},
                .flags = &flags,
            });
        }
        if (diskaudio) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/audio/disk"),
                .files = &.{"SDL_diskaudio.c"},
                .flags = &flags,
            });
        }
        if (alsa) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/audio/alsa"),
                .files = &.{"SDL_alsa_audio.c"},
                .flags = &flags,
            });
        }
        if (jack) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/audio/jack"),
                .files = &.{"SDL_jackaudio.c"},
                .flags = &flags,
            });
        }
        if (pipewire) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/audio/pipewire"),
                .files = &.{"SDL_pipewire.c"},
                .flags = &flags,
            });
        }
        if (pulseaudio) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/audio/pulseaudio"),
                .files = &.{"SDL_pulseaudio.c"},
                .flags = &flags,
            });
        }
        if (sndio) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/audio/sndio"),
                .files = &.{"SDL_sndioaudio.c"},
                .flags = &flags,
            });
        }
        if (windows) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/audio/directsound"),
                .files = &.{"SDL_directsound.c"},
                .flags = &flags,
            });
        }
        if (apple) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/audio/coreaudio"),
                .files = &.{"SDL_coreaudio.m"},
                .flags = &flags,
            });
        }
    }

    if (camera) {
        if (dummycamera) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/camera/dummy"),
                .files = &.{"SDL_camera_dummy.c"},
                .flags = &flags,
            });
        }
        if (pipewire) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/camera/pipewire"),
                .files = &.{"SDL_camera_pipewire.c"},
                .flags = &flags,
            });
        }
        if (windows) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/camera/mediafoundation"),
                .files = &.{"SDL_camera_mediafoundation.c"},
                .flags = &flags,
            });
        }
        if (linux) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/camera/v4l2"),
                .files = &.{"SDL_camera_v4l2.c"},
                .flags = &flags,
            });
        }
        if (apple) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/camera/coremedia"),
                .files = &.{"SDL_camera_coremedia.m"},
                .flags = &flags,
            });
        }
    }

    if (video) {
        if (dummyvideo) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/video/dummy"),
                .files = &.{
                    "SDL_nullevents.c",
                    "SDL_nullframebuffer.c",
                    "SDL_nullvideo.c",
                },
                .flags = &flags,
            });
        }
        if (offscreen) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/video/offscreen"),
                .files = &.{
                    "SDL_offscreenevents.c",
                    "SDL_offscreenframebuffer.c",
                    "SDL_offscreenopengles.c",
                    "SDL_offscreenvideo.c",
                    "SDL_offscreenvulkan.c",
                    "SDL_offscreenwindow.c",
                },
                .flags = &flags,
            });
        }
        if (cocoa) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/video/cocoa"),
                .files = &.{
                    "SDL_cocoaclipboard.m",
                    "SDL_cocoaevents.m",
                    "SDL_cocoakeyboard.m",
                    "SDL_cocoamessagebox.m",
                    "SDL_cocoametalview.m",
                    "SDL_cocoamodes.m",
                    "SDL_cocoamouse.m",
                    "SDL_cocoaopengl.m",
                    "SDL_cocoaopengles.m",
                    "SDL_cocoapen.m",
                    "SDL_cocoashape.m",
                    "SDL_cocoavideo.m",
                    "SDL_cocoavulkan.m",
                    "SDL_cocoawindow.m",
                },
                .flags = &flags,
            });
        }
        if (x11) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/video/x11"),
                .files = &.{
                    "SDL_x11clipboard.c",
                    "SDL_x11dyn.c",
                    "SDL_x11events.c",
                    "SDL_x11framebuffer.c",
                    "SDL_x11keyboard.c",
                    "SDL_x11messagebox.c",
                    "SDL_x11modes.c",
                    "SDL_x11mouse.c",
                    "SDL_x11opengl.c",
                    "SDL_x11opengles.c",
                    "SDL_x11pen.c",
                    "SDL_x11settings.c",
                    "SDL_x11shape.c",
                    "SDL_x11touch.c",
                    "SDL_x11video.c",
                    "SDL_x11vulkan.c",
                    "SDL_x11window.c",
                    "SDL_x11xfixes.c",
                    "SDL_x11xinput2.c",
                    "SDL_x11xsync.c",
                    "edid-parse.c",
                    "xsettings-client.c",
                },
                .flags = &flags,
            });
        }
        if (wayland) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/video/wayland"),
                .files = &.{
                    "SDL_waylandclipboard.c",
                    "SDL_waylandcolor.c",
                    "SDL_waylanddatamanager.c",
                    "SDL_waylanddyn.c",
                    "SDL_waylandevents.c",
                    "SDL_waylandkeyboard.c",
                    "SDL_waylandmessagebox.c",
                    "SDL_waylandmouse.c",
                    "SDL_waylandopengles.c",
                    "SDL_waylandshmbuffer.c",
                    "SDL_waylandvideo.c",
                    "SDL_waylandvulkan.c",
                    "SDL_waylandwindow.c",
                },
                .flags = &flags,
            });
            if (b.lazyDependency("egl", .{ .target = target, .optimize = optimize })) |dep| {
                const lib = dep.artifact("egl");
                mod.linkLibrary(lib);
            }
        }
        if (kmsdrm) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/video/kmsdrm"),
                .files = &.{
                    "SDL_kmsdrmdyn.c",
                    "SDL_kmsdrmevents.c",
                    "SDL_kmsdrmmouse.c",
                    "SDL_kmsdrmopengles.c",
                    "SDL_kmsdrmvideo.c",
                    "SDL_kmsdrmvulkan.c",
                },
                .flags = &flags,
            });
        }
        if (windows) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/video/windows"),
                .files = &.{
                    "SDL_surface_utils.c",
                    "SDL_windowsclipboard.c",
                    "SDL_windowsevents.c",
                    "SDL_windowsframebuffer.c",
                    "SDL_windowsgameinput.c",
                    "SDL_windowskeyboard.c",
                    "SDL_windowsmessagebox.c",
                    "SDL_windowsmodes.c",
                    "SDL_windowsmouse.c",
                    "SDL_windowsopengl.c",
                    "SDL_windowsopengles.c",
                    "SDL_windowsrawinput.c",
                    "SDL_windowsshape.c",
                    "SDL_windowsvideo.c",
                    "SDL_windowsvulkan.c",
                    "SDL_windowswindow.c",
                },
                .flags = &flags,
            });
        }
    }

    if (!sensor) {
        mod.addCSourceFiles(.{
            .root = sdl_dep.path("src/sensor/dummy"),
            .files = &.{"SDL_dummysensor.c"},
            .flags = &flags,
        });
    }

    mod.addCSourceFiles(.{
        .root = sdl_dep.path("src/dialog"),
        .files = &.{
            "SDL_dialog.c",
            "SDL_dialog_utils.c",
        },
        .flags = &flags,
    });
    if (dialog) {
        if (windows) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/dialog/windows"),
                .files = &.{
                    "SDL_windowsdialog.c",
                },
                .flags = &flags,
            });
        }
        if (apple) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/dialog/cocoa"),
                .files = &.{"SDL_cocoadialog.m"},
                .flags = &flags,
            });
        }
        if (linux) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/dialog/unix"),
                .files = &.{
                    "SDL_unixdialog.c",
                    "SDL_portaldialog.c",
                    "SDL_zenitydialog.c",
                },
                .flags = &flags,
            });
        }
    } else {
        mod.addCSourceFiles(.{
            .root = sdl_dep.path("src/dialog/dummy"),
            .files = &.{"SDL_dummydialog.c"},
            .flags = &flags,
        });
    }

    if (gpu) {
        if (render_d3d12) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/gpu/d3d12"),
                .files = &.{
                    "SDL_gpu_d3d12.c",
                },
                .flags = &flags,
            });
        }
        if (vulkan) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/gpu/vulkan"),
                .files = &.{
                    "SDL_gpu_vulkan.c",
                },
                .flags = &flags,
            });
        }
        if (metal) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/gpu/metal"),
                .files = &.{
                    "SDL_gpu_metal.m",
                },
                .flags = &flags,
            });
        }
    }

    if (haptic) {
        if (windows) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/haptic/windows"),
                .files = &.{
                    "SDL_dinputhaptic.c",
                    "SDL_windowshaptic.c",
                },
                .flags = &flags,
            });
        }
        if (linux) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/haptic/linux"),
                .files = &.{"SDL_syshaptic.c"},
                .flags = &flags,
            });
        }
        if (apple) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/haptic/darwin"),
                .files = &.{"SDL_syshaptic.m"},
                .flags = &flags,
            });
        }
    }

    if (power) {
        if (windows) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/power/windows"),
                .files = &.{"SDL_syspower.c"},
                .flags = &flags,
            });
        }
        if (linux) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/power/linux"),
                .files = &.{"SDL_syspower.c"},
                .flags = &flags,
            });
        }
        if (apple) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/power/macos"),
                .files = &.{"SDL_syspower.c"},
                .flags = &flags,
            });
        }
    }

    if (render) {
        if (render_d3d) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/render/direct3d"),
                .files = &.{
                    "SDL_render_d3d.c",
                    "SDL_shaders_d3d.c",
                },
                .flags = &flags,
            });
        }
        if (render_d3d11) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/render/direct3d11"),
                .files = &.{
                    "SDL_render_d3d11.c",
                    "SDL_shaders_d3d11.c",
                },
                .flags = &flags,
            });
        }
        if (render_d3d12) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/render/direct3d12"),
                .files = &.{
                    "SDL_render_d3d12.c",
                    "SDL_shaders_d3d12.c",
                },
                .flags = &flags,
            });
        }
        if (render_vulkan) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/render/vulkan"),
                .files = &.{
                    "SDL_render_vulkan.c",
                    "SDL_shaders_vulkan.c",
                },
                .flags = &flags,
            });
        }
        if (render_gpu) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/render/gpu"),
                .files = &.{
                    "SDL_pipeline_gpu.c",
                    "SDL_render_gpu.c",
                    "SDL_shaders_gpu.c",
                },
                .flags = &flags,
            });
        }
        if (render_metal) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/render/metal"),
                .files = &.{"SDL_render_metal.m"},
                .flags = &flags,
            });
        }
        if (opengl) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/render/opengl"),
                .files = &.{
                    "SDL_render_gl.c",
                    "SDL_shaders_gl.c",
                },
                .flags = &flags,
            });
        }
        if (opengles) {
            mod.addCSourceFiles(.{
                .root = sdl_dep.path("src/render/opengles2"),
                .files = &.{
                    "SDL_render_gles2.c",
                    "SDL_shaders_gles2.c",
                },
                .flags = &flags,
            });
        }
    }

    const lib = b.addLibrary(.{
        .name = "sdl3",
        .root_module = mod,
        .linkage = linkage,
    });
    lib.step.dependOn(legalize_step);
    if (linkage == .dynamic) {
        lib.setVersionScript(sdl_dep.path("src/dynapi/SDL_dynapi.sym"));
        lib.linker_allow_undefined_version = true;
    }
    lib.installHeadersDirectory(sdl_dep.path("include/SDL3"), "SDL3", .{});
    b.installArtifact(lib);
}

const common_sources = .{
    "SDL.c",
    "SDL_assert.c",
    "SDL_error.c",
    "SDL_guid.c",
    "SDL_hashtable.c",
    "SDL_hints.c",
    "SDL_list.c",
    "SDL_log.c",
    "SDL_properties.c",
    "SDL_utils.c",
    "atomic/SDL_atomic.c",
    "atomic/SDL_spinlock.c",
    "audio/SDL_audio.c",
    "audio/SDL_audiocvt.c",
    "audio/SDL_audiodev.c",
    "audio/SDL_audioqueue.c",
    "audio/SDL_audioresample.c",
    "audio/SDL_audiotypecvt.c",
    "audio/SDL_mixer.c",
    "audio/SDL_wave.c",
    "camera/SDL_camera.c",
    "core/SDL_core_unsupported.c",
    "cpuinfo/SDL_cpuinfo.c",
    "dynapi/SDL_dynapi.c",
    "events/imKStoUCS.c",
    "events/SDL_categories.c",
    "events/SDL_clipboardevents.c",
    "events/SDL_displayevents.c",
    "events/SDL_dropevents.c",
    "events/SDL_events.c",
    "events/SDL_eventwatch.c",
    "events/SDL_keyboard.c",
    "events/SDL_keymap.c",
    "events/SDL_keysym_to_keycode.c",
    "events/SDL_keysym_to_scancode.c",
    "events/SDL_mouse.c",
    "events/SDL_pen.c",
    "events/SDL_quit.c",
    "events/SDL_scancode_tables.c",
    "events/SDL_touch.c",
    "events/SDL_windowevents.c",
    "filesystem/SDL_filesystem.c",
    "gpu/SDL_gpu.c",
    "haptic/SDL_haptic.c",
    "hidapi/SDL_hidapi.c",
    "io/generic/SDL_asyncio_generic.c",
    "io/SDL_asyncio.c",
    "io/SDL_iostream.c",
    "joystick/controller_type.c",
    "joystick/SDL_gamepad.c",
    "joystick/SDL_joystick.c",
    "joystick/SDL_steam_virtual_gamepad.c",
    "locale/SDL_locale.c",
    "main/SDL_main_callbacks.c",
    "main/SDL_runapp.c",
    "misc/SDL_url.c",
    "power/SDL_power.c",
    "render/SDL_render_unsupported.c",
    "render/SDL_render.c",
    "render/SDL_yuv_sw.c",
    "render/software/SDL_blendfillrect.c",
    "render/software/SDL_blendline.c",
    "render/software/SDL_blendpoint.c",
    "render/software/SDL_drawline.c",
    "render/software/SDL_drawpoint.c",
    "render/software/SDL_render_sw.c",
    "render/software/SDL_rotate.c",
    "render/software/SDL_triangle.c",
    "sensor/SDL_sensor.c",
    "stdlib/SDL_crc16.c",
    "stdlib/SDL_crc32.c",
    "stdlib/SDL_getenv.c",
    "stdlib/SDL_iconv.c",
    "stdlib/SDL_malloc.c",
    "stdlib/SDL_memcpy.c",
    "stdlib/SDL_memmove.c",
    "stdlib/SDL_memset.c",
    "stdlib/SDL_mslibc.c",
    "stdlib/SDL_murmur3.c",
    "stdlib/SDL_qsort.c",
    "stdlib/SDL_random.c",
    "stdlib/SDL_stdlib.c",
    "stdlib/SDL_string.c",
    "stdlib/SDL_strtokr.c",
    "storage/SDL_storage.c",
    "thread/SDL_thread.c",
    "process/dummy/SDL_dummyprocess.c",
    "time/SDL_time.c",
    "timer/SDL_timer.c",
    "tray/SDL_tray_utils.c",
    "process/SDL_process.c",
    "video/SDL_blit_0.c",
    "video/SDL_blit_1.c",
    "video/SDL_blit_A.c",
    "video/SDL_blit_auto.c",
    "video/SDL_blit_copy.c",
    "video/SDL_blit_N.c",
    "video/SDL_blit_slow.c",
    "video/SDL_blit.c",
    "video/SDL_bmp.c",
    "video/SDL_clipboard.c",
    "video/SDL_egl.c",
    "video/SDL_fillrect.c",
    "video/SDL_pixels.c",
    "video/SDL_rect.c",
    "video/SDL_RLEaccel.c",
    "video/SDL_stb.c",
    "video/SDL_stretch.c",
    "video/SDL_surface.c",
    "video/SDL_video_unsupported.c",
    "video/SDL_video.c",
    "video/SDL_vulkan_utils.c",
    "video/SDL_yuv.c",
    "video/yuv2rgb/yuv_rgb_lsx.c",
    "video/yuv2rgb/yuv_rgb_sse.c",
    "video/yuv2rgb/yuv_rgb_std.c",
};

const uclibc_sources = .{
    "libm/e_atan2.c",
    "libm/e_exp.c",
    "libm/e_fmod.c",
    "libm/e_log.c",
    "libm/e_log10.c",
    "libm/e_pow.c",
    "libm/e_rem_pio2.c",
    "libm/e_sqrt.c",
    "libm/k_cos.c",
    "libm/k_rem_pio2.c",
    "libm/k_sin.c",
    "libm/k_tan.c",
    "libm/s_atan.c",
    "libm/s_copysign.c",
    "libm/s_cos.c",
    "libm/s_fabs.c",
    "libm/s_floor.c",
    "libm/s_isinf.c",
    "libm/s_isinff.c",
    "libm/s_isnan.c",
    "libm/s_isnanf.c",
    "libm/s_modf.c",
    "libm/s_scalbn.c",
    "libm/s_sin.c",
    "libm/s_tan.c",
};

const windows_sources = .{
    "core/windows/pch.c",
    "core/windows/pch.c",
    "core/windows/SDL_gameinput.c",
    "core/windows/SDL_hid.c",
    "core/windows/SDL_hid.c",
    "core/windows/SDL_immdevice.c",
    "core/windows/SDL_immdevice.c",
    "core/windows/SDL_windows.c",
    "core/windows/SDL_windows.c",
    "core/windows/SDL_xinput.c",
    "core/windows/SDL_xinput.c",
    "filesystem/windows/SDL_sysfilesystem.c",
    "filesystem/windows/SDL_sysfsops.c",
    "io/windows/SDL_asyncio_windows_ioring.c",
    "loadso/windows/SDL_sysloadso.c",
    "locale/windows/SDL_syslocale.c",
    "main/generic/SDL_sysmain_callbacks.c",
    "main/windows/SDL_sysmain_runapp.c",
    "misc/windows/SDL_sysurl.c",
    "process/windows/SDL_windowsprocess.c",
    "sensor/windows/SDL_windowssensor.c",
    "storage/generic/SDL_genericstorage.c",
    "storage/steam/SDL_steamstorage.c",
    "time/windows/SDL_systime.c",
    "timer/windows/SDL_systimer.c",
    "tray/windows/SDL_tray.c",
    "process/windows/SDL_windowsprocess.c",
};

const linux_sources = .{
    "core/linux/SDL_evdev_capabilities.c",
    "core/linux/SDL_evdev_kbd.c",
    "core/linux/SDL_evdev.c",
    "core/linux/SDL_ibus.c",
    "core/linux/SDL_ime.c",
    "core/linux/SDL_threadprio.c",
    "core/linux/SDL_udev.c",
    "core/unix/SDL_appid.c",
    "core/unix/SDL_poll.c",
    "filesystem/posix/SDL_sysfsops.c",
    "filesystem/unix/SDL_sysfilesystem.c",
    "io/io_uring/SDL_asyncio_liburing.c",
    "loadso/dlopen/SDL_sysloadso.c",
    "locale/unix/SDL_syslocale.c",
    "main/generic/SDL_sysmain_callbacks.c",
    "misc/unix/SDL_sysurl.c",
    "process/posix/SDL_posixprocess.c",
    "storage/generic/SDL_genericstorage.c",
    "storage/steam/SDL_steamstorage.c",
    "time/unix/SDL_systime.c",
    "timer/unix/SDL_systimer.c",
    "tray/unix/SDL_tray.c",
};

const apple_sources = .{
    "filesystem/cocoa/SDL_sysfilesystem.m",
    "filesystem/posix/SDL_sysfsops.c",
    "loadso/dlopen/SDL_sysloadso.c",
    "locale/macos/SDL_syslocale.m",
    "main/generic/SDL_sysmain_callbacks.c",
    "misc/macos/SDL_sysurl.m",
    "process/posix/SDL_posixprocess.c",
    "storage/generic/SDL_genericstorage.c",
    "storage/steam/SDL_steamstorage.c",
    "time/unix/SDL_systime.c",
    "timer/unix/SDL_systimer.c",
    "tray/cocoa/SDL_tray.m",
    "process/posix/SDL_posixprocess.c",
};

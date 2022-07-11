# Building Fully Static Binaries

This Dockerfile is based on alpine linux which uses Musl instead of Glibc as c library. Musl allows fully static builds.

CLion supports Docker toolchains for compiling and debugging.
Using this a container from this Dockerfile, you make sure that you **do not rely on any system libraries implicitly**.

It contains:

- clang{,++}-14 + lldb
- g{cc,++}-12 + gdb
- various build tools
- ld replaced with mold (linker)
- statically built tcmalloc from gperftools
- git, pip, java-11, linux-headers

# Build It

The repository takes credentials for http://conan.dice-research.org/ as build_args.
**So, you must build it locally and must not upload the built image to a public repository.**

Command for building it:

```shell
docker build --build-arg CONAN_USER=your_username --build-arg CONAN_PW=your_password --tag alpine-cpp-build .
```

# Troubleshooting

## Linking Fails

It seems like some packages from conan central do not link correctly alpine. The easies workaround is to build all of
them locally (in the container).
This can be done, e.g. with:

```dockerfile
# build and cache dependencies via conan
RUN mkdir -p "/home/${USER}/conan_cache"
WORKDIR /home/${USER}/conan_cache
COPY --chown="$USER" conanfile.txt .
RUN conan install . --build=* --profile default
```

Make sure that the profiles are exactly the same between conan_cache and your actual build.

# CLion Integration

Check out CLion [documentation](https://www.jetbrains.com/help/clion/clion-toolchains-in-docker.html)
and [blog posts](https://blog.jetbrains.com/clion/2020/01/using-docker-with-clion/) regarding using a Docker toolchain in CLion. 
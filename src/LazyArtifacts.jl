# This file is a part of Julia. License is MIT: https://julialang.org/license

module LazyArtifacts

# reexport the Artifacts API
using Artifacts: Artifacts,
       artifact_exists, artifact_path, artifact_meta, artifact_hash,
       select_downloadable_artifacts, find_artifacts_toml, @artifact_str
export artifact_exists, artifact_path, artifact_meta, artifact_hash,
       select_downloadable_artifacts, find_artifacts_toml, @artifact_str

# Pkg does the downloading, but it is loaded only when an artifact actually needs
# installing, so `using LazyArtifacts` does not pull Pkg in on every package load.
const PKG_ID = Base.PkgId(Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"), "Pkg")

"""
    ensure_artifact_installed(args...; kwargs...)

Install a lazy artifact through `Pkg.Artifacts.ensure_artifact_installed`, loading Pkg on
first use. Called by `@artifact_str` for artifacts marked `lazy = true`.
"""
function ensure_artifact_installed(args...; kwargs...)
    # Resolve Pkg as `using Pkg` would, so a later `using Pkg` shares the copy and a
    # download during precompilation records Pkg as a dependency of the cache file.
    Pkg = Base.require(PKG_ID)
    return Base.invokelatest(Pkg.Artifacts.ensure_artifact_installed, args...; kwargs...)
end

# Precompile the `Val{LazyArtifacts}` flavour of `@artifact_str` dispatch so that
# JLL packages using `using LazyArtifacts` don't pay codegen cost at `__init__`.
precompile(Tuple{typeof(Artifacts._artifact_str), Module, String, SubString{String}, String,
                 Dict{String,Any}, Base.SHA1, Base.BinaryPlatforms.Platform, Val{LazyArtifacts}})
precompile(Tuple{typeof(Artifacts.__artifact_str), Module, String, SubString{String}, String,
                 Dict{String,Any}, Base.SHA1, Base.BinaryPlatforms.Platform, Val{LazyArtifacts}})

end

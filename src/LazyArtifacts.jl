# This file is a part of Julia. License is MIT: https://julialang.org/license

module LazyArtifacts

# reexport the Artifacts API
using Artifacts: Artifacts,
       artifact_exists, artifact_path, artifact_meta, artifact_hash,
       select_downloadable_artifacts, find_artifacts_toml, @artifact_str
export artifact_exists, artifact_path, artifact_meta, artifact_hash,
       select_downloadable_artifacts, find_artifacts_toml, @artifact_str

# Pkg does the downloading. It stays a declared dependency but is only loaded once an
# artifact actually needs installing, so `using LazyArtifacts` does not pull Pkg in on
# every package load.

"""
    ensure_artifact_installed(name::String, artifacts_toml::String; platform, kwargs...)
    ensure_artifact_installed(name::String, meta::Dict, artifacts_toml::String; platform, kwargs...)

Ensure the artifact is installed, downloading it through
`Pkg.Artifacts.ensure_artifact_installed` if it is not. Pkg is loaded on first use. Called
by `@artifact_str` for artifacts marked `lazy = true`.
"""
function ensure_artifact_installed(name::String, artifacts_toml::String;
                                   platform::Base.BinaryPlatforms.AbstractPlatform = Base.BinaryPlatforms.HostPlatform(),
                                   pkg_uuid::Union{Base.UUID, Nothing} = nothing, kwargs...)
    meta = artifact_meta(name, artifacts_toml; pkg_uuid, platform)
    meta === nothing && error("Cannot locate artifact '$(name)' in '$(artifacts_toml)'")
    return ensure_artifact_installed(name, meta, artifacts_toml; platform, kwargs...)
end

function ensure_artifact_installed(name::String, meta::Dict, artifacts_toml::String;
                                   platform::Base.BinaryPlatforms.AbstractPlatform = Base.BinaryPlatforms.HostPlatform(),
                                   kwargs...)
    hash = Base.SHA1(meta["git-tree-sha1"])
    artifact_exists(hash) && return artifact_path(hash)
    # Loaded as a regular dependency, so a later `using Pkg` shares the copy and a download
    # during precompilation records Pkg as a dependency of the cache file.
    Pkg = Base.require(@__MODULE__, :Pkg)
    return Base.invokelatest(Pkg.Artifacts.ensure_artifact_installed, name, meta, artifacts_toml; platform, kwargs...)::String
end

# Precompile the `Val{LazyArtifacts}` flavour of `@artifact_str` dispatch so that
# JLL packages using `using LazyArtifacts` don't pay codegen cost at `__init__`.
precompile(Tuple{typeof(Artifacts._artifact_str), Module, String, SubString{String}, String,
                 Dict{String,Any}, Base.SHA1, Base.BinaryPlatforms.Platform, Val{LazyArtifacts}})
precompile(Tuple{typeof(Artifacts.__artifact_str), Module, String, SubString{String}, String,
                 Dict{String,Any}, Base.SHA1, Base.BinaryPlatforms.Platform, Val{LazyArtifacts}})

end

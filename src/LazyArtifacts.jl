# This file is a part of Julia. License is MIT: https://julialang.org/license

module LazyArtifacts

# reexport the Artifacts API
using Artifacts: Artifacts,
       artifact_exists, artifact_path, artifact_meta, artifact_hash,
       select_downloadable_artifacts, find_artifacts_toml, @artifact_str
export artifact_exists, artifact_path, artifact_meta, artifact_hash,
       select_downloadable_artifacts, find_artifacts_toml, @artifact_str

using Base.BinaryPlatforms: AbstractPlatform, HostPlatform
using Base: SHA1

"""
       ensure_artifact_installed(name::String, artifacts_toml::String;
                                   platform::AbstractPlatform = HostPlatform(),
                                   pkg_uuid::Union{Base.UUID,Nothing}=nothing,
                                   verbose::Bool = false,
                                   quiet_download::Bool = false,
                                   io::IO=stderr)

Ensures an artifact is installed, downloading it via the download information stored in
`artifacts_toml` if necessary.  Throws an error if unable to install.
"""
function ensure_artifact_installed(name::String, artifacts_toml::String;
    platform::AbstractPlatform=HostPlatform(),
    pkg_uuid::Union{Base.UUID,Nothing}=nothing,
    verbose::Bool=false,
    quiet_download::Bool=false,
    io::IO=stderr)
    meta = artifact_meta(name, artifacts_toml; pkg_uuid=pkg_uuid, platform=platform)
    if meta === nothing
        error("Cannot locate artifact '$(name)' in '$(artifacts_toml)'")
    end

    return ensure_artifact_installed(name, meta, artifacts_toml;
        platform, verbose, quiet_download, io)
end

function ensure_artifact_installed(name::String, meta::Dict, artifacts_toml::String;
    platform::AbstractPlatform=HostPlatform(),
    verbose::Bool=false,
    quiet_download::Bool=false,
    io::IO=stderr)

    hash = SHA1(meta["git-tree-sha1"])
    if !artifact_exists(hash)
        # loading Pkg is a bit slow, so we only do it if we need to
        # and do it in a subprocess to avoid precompilation complexity
        cmd = run(pipeline(`$(Base.julia_cmd()) -E '
                Pkg = Base.require_stdlib(Base.PkgId(Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"), "Pkg"));
                Pkg.try_artifact_download_sources(
                    $(repr(name)),
                    $(repr(hash)),
                    $(repr(meta)),
                    $(repr(artifacts_toml));
                    platform = $(repr(platform)),
                    verbose = $(repr(verbose)),
                    quiet_download = $(repr(quiet_download)),
                    io = $(repr(io))
                )'`,
            stderr=stderr))
        return read(cmd, String)
    else
        return artifact_path(hash)
    end
end

end

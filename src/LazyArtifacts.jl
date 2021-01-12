module LazyArtifacts

# reexport the Artifacts API
using Pkg.Artifacts: Artifacts,
       artifact_exists, artifact_path, artifact_meta, artifact_hash,
       find_artifacts_toml, @artifact_str
export artifact_exists, artifact_path, artifact_meta, artifact_hash,
       find_artifacts_toml, @artifact_str

# define a function for satisfying lazy Artifact downloads
using Pkg.Artifacts: ensure_artifact_installed

end

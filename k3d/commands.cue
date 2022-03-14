package k3d

import (
	"encoding/yaml"
	"tool/exec"
	"tool/file"
	"tool/cli"
	"github.com/defn/boot/input"
)

#K3D: ctx={
	input.#Input
	#K3DConfig

	config: {
		mergeKubeConfig: exec.Run & {
			cmd: ["k3d", "kubeconfig", "merge", "-d", "-s", ctx.k3d_name]
		}
	}

	"k3d-registry": {
		createRegistry: exec.Run & {
			cmd: ["k3d", "registry", "create", "registry.localhost", "--port", "5555"]
		}
	}

	up: {
		saveConfig: file.Create & {
			filename: "k3d.yaml"
			contents: yaml.Marshal(ctx.output)
		}
		createCluster: exec.Run & {
			$after: saveConfig
			cmd: ["k3d", "cluster", "create", "--config", "k3d.yaml"]
		}
	}

	down: {
		deleteCluster: exec.Run & {
			cmd: ["k3d", "cluster", "delete", ctx.k3d_name]
		}
	}

	context: {
		createCluster: exec.Run & {
			cmd: ["kubectl", "config", "use-context", "k3d-\(ctx.k3d_name)"]
		}
	}

	_manifest: [
		for aname, a in ctx.app // app: defm: {}
		for kname, kinds in a.output // app: defm: output: namespace: {}
		for k in kinds  // app: defm: output: namespace: [name]: {}
		{ k }
	]

	plan: cli.Print & {
        text: yaml.MarshalStream(_manifest)
    }

	apply: exec.Run & {
		stdin: yaml.MarshalStream(_manifest)
        cmd: ["kubectl", "--context", "k3d-\(ctx.k3d_name)", "apply", "-f", "-"]
    }
}

package k3d

import (
	App "github.com/defn/boot/app"
)

#K3DConfig: {
	k3d_name:    string
	k3d_host:    string
	k3d_ip:      string
	k3d_image:   string | *"rancher/k3s:v1.22.8-k3s1"
	k3d_ports:   [...string] | *[]
	k3d_network: string | *"bridge"

	app: [aname=string]: App.#App & {
		app_name: aname
	}

	output: {
		apiVersion: "k3d.io/v1alpha4"
		kind:       "Simple"
		metadata: name: k3d_name
		servers: 1
		agents:  0
		kubeAPI: {
			host:   k3d_host
			hostIP: "0.0.0.0"
		}
		image: k3d_image
		if k3d_network != "bridge" {
			network: k3d_network
		}
		volumes: [{
			volume: "/var/run/docker.sock:/var/run/docker.sock"
			nodeFilters: [
				"server:0",
			]
		}, {
			volume: "k3d-password-store:/mnt/password-store"
			nodeFilters: [
				"server:0",
			]
		}, {
			volume: "k3d-kube:/mnt/kube"
			nodeFilters: [
				"server:0",
			]
		}, {
			volume: "k3d-work:/mnt/work"
			nodeFilters: [
				"server:0",
			]
		}]
		options: {
			k3d: {
				wait:                true
				timeout:             "360s"
				disableLoadbalancer: false
			}
			k3s: extraArgs: [{
				arg: "--tls-san=\(k3d_ip)"
				nodeFilters: [
					"server:0",
				]
			}, {
				arg: "--tls-san=\(k3d_host)"
				nodeFilters: [
					"server:0",
				]
			}, {
				arg: "--disable=traefik"
				nodeFilters: [
					"server:0",
				]
			}, {
				arg: "--node-external-ip=\(k3d_ip)"
				nodeFilters: [
					"server:0",
				]
			}]
			kubeconfig: {
				updateDefaultKubeconfig: true
				switchCurrentContext:    false
			}
		}
		if k3d_network != "host" {
			registries: use: ["k3d-registry.localhost:5555"]
		}

		if len(k3d_ports) > 0 {
			ports: [
				for p in k3d_ports {
					port: p
					nodeFilters: [ "loadbalancer"]
				},
			]
		}
	}
}

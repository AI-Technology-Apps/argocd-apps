import os
import yaml

BASE_DIR = "apps"
CONFIG_NAME = "chart-config.yaml"
applications = []

for app_dir in os.listdir(BASE_DIR):
    config_path = os.path.join(BASE_DIR, app_dir, CONFIG_NAME)
    if not os.path.isfile(config_path):
        continue

    with open(config_path) as f:
        app_config = yaml.safe_load(f)
        app_config["appPath"] = f"./{BASE_DIR}/{app_dir}"
        applications.append(app_config)

appset = {
    "apiVersion": "argoproj.io/v1alpha1",
    "kind": "ApplicationSet",
    "metadata": {
        "name": "generated-appset",
        "namespace": "argocd"
    },
    "spec": {
        "generators": [{"list": {"elements": applications}}],
        "template": {
            "metadata": {
                "name": "{{name}}"
            },
            "spec": {
                "project": "default",
                "destination": {
                    "server": "https://kubernetes.default.svc",
                    "namespace": "{{name}}"
                },
                "source": {
                    "repoURL": "{{repoURL}}",
                    "chart": "{{chart}}",
                    "path": "{{appPath}}",
                    "targetRevision": "{{version}}"
                },
                "syncPolicy": {
                    "automated": {
                        "prune": True,
                        "selfHeal": True
                    }
                }
            }
        }
    }
}

with open("manifests/generated-applicationset.yaml", "w") as f:
    yaml.dump(appset, f, sort_keys=False)

print("✅ generated-applicationset.yaml created")
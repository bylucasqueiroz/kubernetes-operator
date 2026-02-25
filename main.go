package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"time"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/rest"
)

func main() {
	// In-cluster config
	config, err := rest.InClusterConfig()
	if err != nil {
		log.Fatal(err)
	}

	client, err := dynamic.NewForConfig(config)
	if err != nil {
		log.Fatal(err)
	}

	http.HandleFunc("/update", func(w http.ResponseWriter, r *http.Request) {
		namespace := r.URL.Query().Get("namespace")
		name := r.URL.Query().Get("name")

		if namespace == "" || name == "" {
			http.Error(w, "namespace and name are required", 400)
			return
		}

		gvr := schema.GroupVersionResource{
			Group:    "argoproj.io",
			Version:  "v1alpha1",
			Resource: "applicationsets",
		}

		patch := map[string]interface{}{
			"spec": map[string]interface{}{
				"template": map[string]interface{}{
					"metadata": map[string]interface{}{
						"annotations": map[string]interface{}{
							"updated-by": "minikube-test",
						},
					},
				},
			},
		}

		payload, _ := json.Marshal(patch)

		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		_, err := client.
			Resource(gvr).
			Namespace(namespace).
			Patch(ctx, name, types.MergePatchType, payload, metav1.PatchOptions{})
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}

		w.Write([]byte("ApplicationSet updated"))
	})

	log.Println("Server running on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

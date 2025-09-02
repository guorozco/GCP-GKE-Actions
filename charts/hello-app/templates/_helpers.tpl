{{/*
Expand the name of the chart.
*/}}
{{- define "hello-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hello-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hello-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hello-app.labels" -}}
helm.sh/chart: {{ include "hello-app.chart" . }}
{{ include "hello-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.app.environment }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hello-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hello-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ .Values.app.name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "hello-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hello-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate the image name
*/}}
{{- define "hello-app.image" -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag }}
{{- end }}

{{/*
Generate environment variables
*/}}
{{- define "hello-app.env" -}}
{{- range .Values.env }}
- name: {{ .name }}
  value: {{ .value | quote }}
{{- end }}
{{- end }}

{{/*
Generate resource configuration
*/}}
{{- define "hello-app.resources" -}}
{{- if .Values.resources }}
resources:
  {{- toYaml .Values.resources | nindent 2 }}
{{- end }}
{{- end }}

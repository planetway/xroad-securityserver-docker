{{/*
Expand the name of the chart.
*/}}
{{- define "xroad-securityserver.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "xroad-securityserver.fullname" -}}
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
{{- define "xroad-securityserver.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "xroad-securityserver.labels" -}}
helm.sh/chart: {{ include "xroad-securityserver.chart" . }}
{{ include "xroad-securityserver.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "xroad-securityserver.selectorLabels" -}}
app.kubernetes.io/name: {{ include "xroad-securityserver.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "xroad-securityserver.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "xroad-securityserver.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Primary labels
*/}}
{{- define "xroad-securityserver-primary.labels" -}}
helm.sh/chart: {{ include "xroad-securityserver.chart" . }}
{{ include "xroad-securityserver-primary.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Primary selector labels
*/}}
{{- define "xroad-securityserver-primary.selectorLabels" -}}
app.kubernetes.io/name: {{ include "xroad-securityserver.name" . }}-primary
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Secondary labels
*/}}
{{- define "xroad-securityserver-secondary.labels" -}}
helm.sh/chart: {{ include "xroad-securityserver.chart" . }}
{{ include "xroad-securityserver-secondary.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Secondary selector labels
*/}}
{{- define "xroad-securityserver-secondary.selectorLabels" -}}
app.kubernetes.io/name: {{ include "xroad-securityserver.name" . }}-secondary
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common service selector labels
*/}}
{{- define "xroad-securityserver-common-service.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

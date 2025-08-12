package main

import (
	commonconfig "github.com/criage-oss/criage-common/config"
	commontypes "github.com/criage-oss/criage-common/types"
)

// Используем общие типы для унификации API (camelCase)
type PackageEntry = commontypes.PackageEntry

type VersionEntry = commontypes.VersionEntry

type FileEntry = commontypes.FileEntry

type RepositoryIndex = commontypes.RepositoryIndex

type Statistics = commontypes.Statistics

type SearchResult = commontypes.SearchResult

// UploadRequest запрос на загрузку пакета
type UploadRequest struct {
	Token       string `json:"token"`
	PackageName string `json:"package_name"`
	Version     string `json:"version"`
	OS          string `json:"os"`
	Arch        string `json:"arch"`
	Format      string `json:"format"`
}

type ApiResponse = commontypes.ApiResponse

// Конфигурация сервера репозитория (переведена на общий тип)
type Config = commonconfig.ServerConfig

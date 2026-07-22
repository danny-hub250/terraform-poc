provider "azurerm" {
  features {}

  # skbax-rnd-prd는 새로 만든 구독이라 azurerm의 기본 "core" Resource Provider
  # 목록(Microsoft.ManagedIdentity, Microsoft.ContainerService 등 11개)이 전부
  # 미등록 상태였고, provider가 이를 등록 완료까지 순차 대기하면서 plan/apply가
  # 멈춘 것처럼 보였음. 등록은 az provider register로 별도 진행하고,
  # terraform은 대기하지 않도록 설정.
  resource_provider_registrations = "none"
}

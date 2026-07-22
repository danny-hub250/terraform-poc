# Microsoft Defender for Servers (jumpbox VM 백신/위협 탐지용)
#
# 주의: azurerm_security_center_subscription_pricing은 리소스 그룹이나 개별
# VM이 아니라 "구독 전체" 단위로 적용됩니다. 이 리소스를 apply하면 현재 활성
# 구독의 모든 VM(baxpoc-dev, AuditAX-DEV 등 다른 환경 포함)에 Microsoft
# Defender for Endpoint가 자동 배포되고, VM 대수만큼 월 과금(대당 약 $15)이
# 발생합니다. 반대로 이 환경(baxpoc-prd)만 destroy해도 이 설정 자체는 구독
# 전체에 계속 남아있습니다(다른 환경 쪽 state가 이 리소스를 갖고 있지 않다면).
resource "azurerm_security_center_subscription_pricing" "vm" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

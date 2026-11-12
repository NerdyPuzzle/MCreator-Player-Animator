{
  "required": true,
  "package": "${package}.mixin",
  "compatibilityLevel": "JAVA_21",
  "mixins": [
	<#list fragments.mixin as mixin>"${mixin}"<#sep>,</#list>
  ],
  "client": [
    "PlayerAnimationMixin",
    "PlayerAnimationRendererMixin",
    "ItemInHandLayerMixin",
    "CameraAccessor",
    "EntityRenderDispatcherMixin",
    "LivingEntityRendererMixin",
    "EntityRendererMixin",
    "ItemInHandRendererMixin",
    "LevelRendererMixin"
  ],
  "injectors": {
    "defaultRequire": 1
  },
  "minVersion": "0.8.4"
}
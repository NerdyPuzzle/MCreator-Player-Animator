<#assign mixins = []>
<#if w.getGElementsOfType('biome')?filter(e -> e.spawnBiome || e.spawnInCaves || e.spawnBiomeNether)?size != 0>
	<#assign mixins = mixins + ['NoiseGeneratorSettingsMixin']>
</#if>
<#list w.getWorkspace().getModElements() as element>
  <#assign providedmixins = []>
  <#if element.getGeneratableElement().mixins??>
    <#assign providedmixins = element.getGeneratableElement().mixins>
  </#if>
  <#if providedmixins?has_content>
    <#list providedmixins as mixin>
       <#if !mixins?seq_contains(mixin)>
         <#assign mixins += [mixin]>
       </#if>
    </#list>
  </#if>
</#list>
{
  "required": true,
  "package": "${package}.mixin",
  "compatibilityLevel": "JAVA_21",
  "mixins": [
    <#list mixins as mixin>"${mixin}"<#sep>,</#list>
  ],
  "client": [
    "PlayerAnimationMixin",
    "PlayerAnimationRendererMixin"
  ],
  "injectors": {
    "defaultRequire": 1
  },
  "minVersion": "0.8.4"
}
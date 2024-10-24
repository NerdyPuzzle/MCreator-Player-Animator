if (world.isClientSide()) {
	if (${input$entity} instanceof AbstractClientPlayer player) { 
		var animation = (ModifierLayer<IAnimation>) PlayerAnimationAccess.getPlayerAssociatedData(Minecraft.getInstance().player).get(ResourceLocation.fromNamespaceAndPath("${modid}", "player_animation"));
		if (animation != null ${field$active}) {
			animation.replaceAnimationWithFade(AbstractFadeModifier.functionalFadeIn(20, (modelName, type, value) -> value),
                    PlayerAnimationRegistry.getAnimation(ResourceLocation.fromNamespaceAndPath("${modid}", ${input$animation})).playAnimation()
                            .setFirstPersonMode(FirstPersonMode.THIRD_PERSON_MODEL)
                            .setFirstPersonConfiguration(new FirstPersonConfiguration().setShowRightArm(true).setShowLeftItem(false))
            );
		}
	}
}
if (!world.isClientSide()) {
	<#assign procedurename = "">
	<#list w.getGElementsOfType("procedure") as pc>
		<#if pc.procedurexml?contains("player_animations_setup")>
			<#assign procedurename = pc.getModElement().getName()>
		</#if>
	</#list>
	<#assign override = (field$active == "&& !animation.isActive()")?then("false", "true")>
	if (${input$entity} instanceof Player)
		PacketDistributor.ALL.noArg().send(new ${procedurename}Procedure.${JavaModName}AnimationMessage(${input$animation}, ${input$entity}.getId(), ${override}));
}
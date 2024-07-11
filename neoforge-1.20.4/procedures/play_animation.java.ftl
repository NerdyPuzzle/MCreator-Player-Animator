if (world.isClientSide()) {
	if (${input$entity} instanceof AbstractClientPlayer player) { 
		var animation = (ModifierLayer<IAnimation>)PlayerAnimationAccess.getPlayerAssociatedData(player).get(
			new ResourceLocation("${modid}", "player_animation"));
		if (animation != null ${field$active}) {
			animation.setAnimation(new KeyframeAnimationPlayer(PlayerAnimationRegistry.getAnimation(
				new ResourceLocation("${modid}", ${input$animation}))));
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
		PacketDistributor.ALL.noArg().send(new ${procedurename}Procedure.${JavaModName}AnimationMessage(Component.literal(${input$animation}), ${input$entity}.getId(), ${override}));
}
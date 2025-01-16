<#assign procedurename = "">
<#list w.getGElementsOfType("procedure") as pc>
	<#if pc.procedurexml?contains("player_animations_setup")>
		<#assign procedurename = pc.getModElement().getName()>
	</#if>
</#list>
if (world.isClientSide()) {
	${procedurename}Procedure.setAnimationClientside((Player)${input$entity}, ${input$animation}, ${field$active});
}
if (!world.isClientSide()) {
	if (${input$entity} instanceof Player)
		PacketDistributor.sendToPlayersInDimension((ServerLevel)${input$entity}.level(), new ${procedurename}Procedure.${JavaModName}AnimationMessage(${input$animation}, ${input$entity}.getId(), ${field$active}));
}
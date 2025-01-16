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
	if (${input$entity} instanceof Player && world instanceof ServerLevel srvLvl_) {
		List<Connection> connections = srvLvl_.getServer().getConnection().getConnections();
		synchronized(connections) {
			Iterator<Connection> iterator = connections.iterator();
			while(iterator.hasNext()) {
				Connection connection = iterator.next();
				if (!connection.isConnecting() && connection.isConnected())
					${JavaModName}.PACKET_HANDLER.sendTo(new ${procedurename}Procedure.${JavaModName}AnimationMessage(Component.literal(${input$animation}), ${input$entity}.getId(), ${field$active}), connection, NetworkDirection.PLAY_TO_CLIENT);
			}
		}	
	}
}
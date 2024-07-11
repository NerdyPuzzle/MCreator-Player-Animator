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
	if (${input$entity} instanceof Player && world instanceof ServerLevel srvLvl_) {
		List<Connection> connections = srvLvl_.getServer().getConnection().getConnections();
		synchronized(connections) {
			Iterator<Connection> iterator = connections.iterator();
			while(iterator.hasNext()) {
				Connection connection = iterator.next();
				if (!connection.isConnecting() && connection.isConnected())
					${JavaModName}.PACKET_HANDLER.sendTo(new ${procedurename}Procedure.${JavaModName}AnimationMessage(Component.literal(${input$animation}), ${input$entity}.getId(), ${override}), connection, NetworkDirection.PLAY_TO_CLIENT);
			}
		}	
	}
}
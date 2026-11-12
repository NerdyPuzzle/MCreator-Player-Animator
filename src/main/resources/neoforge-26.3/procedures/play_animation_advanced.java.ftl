if (${input$entity} instanceof Player) {
    if (${input$entity}.level().isClientSide()) {
        CompoundTag data = ${input$entity}.getPersistentData();
        data.putString("PlayerCurrentAnimation", "${modid}:" + ${input$animation});
        data.putBoolean("OverrideCurrentAnimation", ${field$active});
        data.putBoolean("FirstPersonAnimation", ${field$firstperson});
    } else {
        PacketDistributor.sendToPlayersInDimension((ServerLevel) ${input$entity}.level(), new PlayPlayerAnimationMessage(${input$entity}.getId(), "${modid}:" + ${input$animation}, ${field$active}, ${field$firstperson}));
    }
}
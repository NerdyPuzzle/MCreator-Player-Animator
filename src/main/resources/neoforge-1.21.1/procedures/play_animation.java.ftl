if (${input$entity} instanceof Player) {
    if (${input$entity}.level().isClientSide()) {
        CompoundTag data = ${input$entity}.getPersistentData();
        data.putString("PlayerCurrentAnimation", "${modid}:${field$animation}");
        data.putBoolean("OverrideCurrentAnimation", ${field$active});
    } else {
        PacketDistributor.sendToPlayersInDimension((ServerLevel) ${input$entity}.level(), new PlayPlayerAnimationMessage(${input$entity}.getId(), "${modid}:${field$animation}", ${field$active}));
    }
}
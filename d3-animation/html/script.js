window.addEventListener("message", function (event) {
    if (event.data.action === "open") {
        document.querySelector(".wheel").classList.remove("hidden");
    } else if (event.data.action === "close") {
        document.querySelector(".wheel").classList.add("hidden");
    }
});

document.querySelectorAll(".slice").forEach(slice => {
    slice.addEventListener("click", () => {
        const emote = slice.dataset.emote;
        fetch(`https://${GetParentResourceName()}/selectEmote`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ emote })
        });
    });
});

document.addEventListener("keydown", (e) => {
    if (e.code === "KeyX") {
        fetch(`https://${GetParentResourceName()}/cancelEmote`, {
            method: "POST"
        });
    }
});

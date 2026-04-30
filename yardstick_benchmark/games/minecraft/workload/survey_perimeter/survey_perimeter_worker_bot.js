
const mineflayer = require('mineflayer');
const pathfinder = require('mineflayer-pathfinder').pathfinder
const Movements = require('mineflayer-pathfinder').Movements
const { GoalXZ } = require('mineflayer-pathfinder').goals
const v = require("vec3");

const { workerData } = require("worker_threads");

const host = workerData.host
const username = workerData.username
const box_x = workerData.box_x
const box_z = workerData.box_z
const box_width = workerData.box_width

// Walk the 4 corners of the bounding box in order, cycling forever.
function corners() {
    return [
        { x: box_x,             z: box_z             },
        { x: box_x + box_width, z: box_z             },
        { x: box_x + box_width, z: box_z + box_width },
        { x: box_x,             z: box_z + box_width },
    ];
}

let worker_bot = mineflayer.createBot({
    host: host,
    username: username,
    port: 25565,
});
worker_bot.on('kicked', console.log)
worker_bot.on('error', console.log)
worker_bot.loadPlugin(pathfinder)
worker_bot.once("spawn", async () => {
    let defaultMove = new Movements(worker_bot)
    defaultMove.allowSprinting = false
    defaultMove.canDig = false
    worker_bot.pathfinder.setMovements(defaultMove)

    const pts = corners();
    let i = 0;
    while (true) {
        const { x, z } = pts[i % pts.length];
        let ts = Date.now() / 1000;
        console.log(`${ts} - bot ${worker_bot.username} heading to corner (${x}, ${z})`);
        try {
            await worker_bot.pathfinder.goto(new GoalXZ(x, z))
        } catch (e) {
            if (e.name != "NoPath" && e.name != "Timeout") {
                throw e
            }
        }
        i++;
    }
});

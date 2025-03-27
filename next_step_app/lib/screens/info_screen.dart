import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

const markdown = r'''
# Stairs Training 🏃‍♂️🦿

Build muscle memory, strength, and confidence in stair navigation. This exercise trains your body to move naturally and efficiently with your bioprosthesis while reducing fall risks.

## How It Works
✅ The system uses ultrasonic sensors to detect the distance to the next step and the floor.  
✅ Real-time color indicators guide your movements for better control and balance.  
✅ Repeated training enhances muscle memory, making stair climbing smoother and more natural over time.  
✅ Strengthens lower body muscles to improve stability and endurance.

## Color Indicators
- 🔴 **[RED]Too Far!** – Your foot is on the floor but too far from the next step. Adjust your stance before stepping to prevent missteps.
- 🟡 **[YELLOW]In Motion!** – Your foot is off the ground. Stay balanced as you transition to the next step.
- 🟢 **[GREEN]Step Ready!** – Your foot is on the ground and correctly positioned for a safe and stable step.

> 💡 **Tip:** Consistent training helps reinforce muscle memory, leading to stronger, more controlled movements over time.

---

**Tap ‘Start’ to begin training! 🚀**

''';

class InfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
  	return Scaffold(
        appBar: AppBar(
        //   title: Text(widget.device.platformName),
        //   actions: [buildConnectButton(context)],
        ),
        body: Markdown(data: markdown)
      );
  }
}
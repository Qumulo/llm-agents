#!/usr/bin/env python3
"""Prevent automated agentsview bumps while 0.26.0 suffers a frontend regression.

Restore the original updater by reverting this file (see git history) once
wesm/agentsview#428 is fixed.
"""

print("Skipping agentsview update: pinned to 0.25.0 due to upstream regression.")

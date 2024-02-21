#!/usr/bin/env python3
#
# Limit the network using tc, optionally interfacing with Docker
#
# Copyright (c) 2024 AVEQ GmbH.
# License: MIT

import argparse
import logging
import subprocess

logging.basicConfig(
    level=logging.DEBUG, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class NetworkLimit:
    # from: https://github.com/tylertreat/comcast
    DEFAULT_PROFILES = {
        "gprs": {"latency": 500, "bandwidth": 50, "packet_loss": 2},
        "edge": {"latency": 300, "bandwidth": 250, "packet_loss": 1.5},
        "3g": {"latency": 250, "bandwidth": 750, "packet_loss": 1.5},
        "dialup": {"latency": 185, "bandwidth": 40, "packet_loss": 2},
        "dsl_poor": {"latency": 70, "bandwidth": 2000, "packet_loss": 2},
        "dsl_good": {"latency": 40, "bandwidth": 8000, "packet_loss": 0.5},
        "wifi": {"latency": 40, "bandwidth": 30000, "packet_loss": 0.2},
        "starlink": {"latency": 20, "bandwidth": -1, "packet_loss": 2.5},
    }

    def __init__(self, interface: str, use_docker: bool, docker_container: str):
        self.interface = interface
        self.use_docker = use_docker
        self.docker_container = docker_container

    def run_command(self, command: list[str], allow_fail: bool = False):
        logger.info(f"Running command: {' '.join(command)}")
        try:
            ret = subprocess.check_output(command, stderr=subprocess.STDOUT, text=True)
            if ret:
                logger.info(f"Command output: {ret}")
        except subprocess.CalledProcessError as e:
            if not allow_fail:
                logger.error(f"Command failed: {e.output}")
                raise

    def apply(self, rate: float, delay: float, loss: float):
        # clear before
        self.clear()

        logger.info(
            f"Applying network limits: rate={rate}Kbps, delay={delay}ms, loss={loss}%"
        )
        base_cmd = [
            *self._command_prefix(),
            "tc",
            "qdisc",
            "add",
            "dev",
            self.interface,
            "root",
            "netem",
        ]

        if rate >= 0:  # -1 == unlimited
            base_cmd.extend(["rate", f"{rate}kbit"])

        if delay > 0:
            base_cmd.extend(["delay", f"{delay}ms"])

        if loss > 0:
            base_cmd.extend(["loss", f"{loss}%"])

        self.run_command(base_cmd)

    def clear(self):
        logger.info("Clearing network limits...")
        self.run_command(
            [
                *self._command_prefix(),
                "tc",
                "qdisc",
                "del",
                "dev",
                self.interface,
                "root",
            ],
            allow_fail=True,
        )

    def _command_prefix(self) -> list[str]:
        if self.use_docker:
            return ["docker", "compose", "exec", self.docker_container]
        else:
            return ["sudo"]


def main():
    parser = argparse.ArgumentParser(
        description="Limit the network using tc.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-i", "--interface", type=str, help="The interface to limit", default="eth0"
    )
    parser.add_argument(
        "--use-docker", action="store_true", help="Use the Docker container instead"
    )
    parser.add_argument(
        "--docker-container",
        type=str,
        help="The name of the Docker container",
        default="web",
    )

    subparsers = parser.add_subparsers(dest="command", help="The command to run")
    parser_apply = subparsers.add_parser("apply", help="Apply the limits")
    parser_apply.add_argument(
        "--rate",
        type=float,
        help="The rate to limit the interface to (in Kbps), use -1 for unlimited",
        default=-1,
    )
    parser_apply.add_argument(
        "--delay",
        type=float,
        help="The delay to add to the interface (in ms)",
        default=0,
    )
    parser_apply.add_argument(
        "--loss", type=float, help="The percentage of packets to drop", default=0.0
    )

    parser_apply_profile = subparsers.add_parser(
        "apply-profile", help="Apply a predefined profile"
    )
    parser_apply_profile.add_argument(
        "profile",
        type=str,
        help="The name of the profile to apply",
        choices=NetworkLimit.DEFAULT_PROFILES.keys(),
    )

    parser_clear = subparsers.add_parser("clear", help="Clear the limits")  # noqa: F841

    args = parser.parse_args()

    network_limit = NetworkLimit(args.interface, args.use_docker, args.docker_container)

    if args.command == "apply":
        network_limit.apply(args.rate, args.delay, args.loss)

    if args.command == "apply-profile":
        profile = NetworkLimit.DEFAULT_PROFILES[args.profile]
        network_limit.apply(
            profile["bandwidth"], profile["latency"], profile["packet_loss"]
        )

    if args.command == "clear":
        network_limit.clear()


if __name__ == "__main__":
    main()

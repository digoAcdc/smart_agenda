import { test } from "node:test";
import assert from "node:assert/strict";
import { assetLinks, isValidInviteToken, renderInvitePage } from "../invite.js";

test("codigo do convite: so letras/numeros sem ambiguidade", () => {
  assert.equal(isValidInviteToken("abcdefghjk23"), true);
  assert.equal(isValidInviteToken("../etc/passwd"), false);
  assert.equal(isValidInviteToken("ABC"), false);
});

test("pagina valida mostra quem convidou e os botoes, sem injetar HTML", () => {
  const html = renderInvitePage("abcdefghjk23", {
    family_name: "Silveira <script>", invited_by_name: "Ana", role: "editor", is_valid: true,
  });
  assert.match(html, /Ana convidou você para a Família Silveira &lt;script&gt;/);
  assert.match(html, /smartagenda:\/\/convite\/abcdefghjk23/);
  assert.match(html, /referrer=convite%3Dabcdefghjk23/);
  assert.doesNotMatch(html, /<script>/);
});

test("convite usado ou vencido avisa e nao oferece abrir", () => {
  const html = renderInvitePage("abcdefghjk23", { is_valid: false });
  assert.match(html, /não está mais valendo/);
  assert.doesNotMatch(html, /smartagenda:\/\//);
});

test("assetlinks com as digitais informadas", () => {
  const [entry] = assetLinks("aa:bb, CC:DD");
  assert.equal(entry.target.package_name, "com.digo.smartagenda");
  assert.ok(entry.target.sha256_cert_fingerprints.includes("AA:BB"));
  assert.ok(entry.target.sha256_cert_fingerprints.includes("CC:DD"));
  assert.ok(entry.target.sha256_cert_fingerprints[0].startsWith("6B:0B"));
  assert.ok(entry.target.sha256_cert_fingerprints[1].startsWith("4B:75"));
});

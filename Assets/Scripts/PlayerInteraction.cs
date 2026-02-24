using UnityEngine;

public class PlayerInteraction : MonoBehaviour
{
    [SerializeField] private float interactionRadius = 0.8f;
    [SerializeField] private LayerMask interactableLayer;

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.E))
        {
            TryInteract();
        }
    }

    private void TryInteract()
    {
        Collider2D hit = Physics2D.OverlapCircle(
            transform.position,
            interactionRadius,
            interactableLayer
        );

        DialogueManager dm = FindObjectOfType<DialogueManager>();

if (dm != null)
{
    dm.ShowDialogue(
        "You received a suspicious email asking for your password.",
        "Ignore it",
        "Click the link",
        () => Debug.Log("Good choice"),
        () => Debug.Log("Bad choice")
    );
}
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(transform.position, interactionRadius);
    }
}